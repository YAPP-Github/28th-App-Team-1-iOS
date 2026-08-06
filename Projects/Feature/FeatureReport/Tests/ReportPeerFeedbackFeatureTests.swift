//
//  ReportPeerFeedbackFeatureTests.swift
//  FeatureReportTests
//
//  Created by EunSeo on 26/07/29.
//

import ComposableArchitecture
import DomainFeedbackShareInterface
import DomainInterviewReportInterface
import Foundation
import Testing

@testable import FeatureReportImplementation

@MainActor
struct ReportPeerFeedbackFeatureTests {
    /// 서버에 이미 만들어 둔 활성 링크 — 회수 경로 확인용 응답.
    private static func activeStatus(axes: [String]) -> FeedbackShareStatus {
        FeedbackShareStatus(
            token: "tok",
            status: .active,
            axes: axes,
            submittedCount: 1,
            videoExpiresAt: nil,
            requestedAt: nil
        )
    }

    @Test("항목을 켠 순서와 무관하게 화면 순서로 서버에 보낸다")
    func sendsAxesInDisplayOrder() async {
        let sent = LockIsolated<[String]>([])
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.create = { _, axes in
                sent.setValue(axes)
                return FeedbackShareCreated(token: "tok")
            }
        }

        // 목소리 → 시선 순으로 켠다.
        await store.send(.view(.userToggledAxis(.voice, isOn: true))) {
            $0.selectedAxes = [.voice]
        }
        await store.send(.view(.userToggledAxis(.gaze, isOn: true))) {
            $0.selectedAxes = [.voice, .gaze]
        }
        await store.send(.view(.userTappedCreateLink)) {
            $0.isCreating = true
        }
        await store.receive(\.inner.shareLinkCreated) {
            $0.isCreating = false
            $0.createdLink = "https://hilit.my/feedback/tok"
            $0.isCompletionModalVisible = true
        }

        #expect(sent.value == ["GAZE", "VOICE"])
    }

    @Test("항목을 하나도 안 고르면 요청하지 않는다")
    func emptySelectionDoesNotCallServer() async {
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        }
        // create 는 testValue(unimplemented) 그대로 — 호출되면 테스트가 실패한다.
        await store.send(.view(.userTappedCreateLink))
    }

    @Test("생성 실패는 사용자 문구로 바뀌고 CTA 가 다시 눌린다")
    func failureSurfacesMessageAndUnlocksCTA() async {
        let clock = TestClock()
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.create = { _, _ in throw FeedbackShareError.networkFailure }
            $0.continuousClock = clock
        }

        await store.send(.view(.userToggledAxis(.gaze, isOn: true))) {
            $0.selectedAxes = [.gaze]
        }
        await store.send(.view(.userTappedCreateLink)) {
            $0.isCreating = true
        }
        await store.receive(\.inner.shareLinkFailed) {
            $0.isCreating = false
            $0.toast = "네트워크 연결을 확인해 주세요."
        }
        await clock.advance(by: .seconds(2))
        await store.receive(\.inner.toastDismissed) {
            $0.toast = nil
        }
        #expect(!store.state.isAxisLocked)
    }

    @Test("409 는 실패로 끝나지 않는다 — 기존 링크를 회수해 완료 모달을 다시 띄운다")
    func alreadyExistsRecoversLink() async {
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.create = { _, _ in throw FeedbackShareError.alreadyExists }
            $0.feedbackShareClient.status = { _ in Self.activeStatus(axes: ["EXPRESSION"]) }
        }

        await store.send(.view(.userToggledAxis(.gaze, isOn: true))) {
            $0.selectedAxes = [.gaze]
        }
        await store.send(.view(.userTappedCreateLink)) {
            $0.isCreating = true
        }
        await store.receive(\.inner.existingShareLoaded) {
            $0.isCreating = false
            // 화면에서 고른 항목이 아니라 **링크에 잠긴** 항목이 남는다.
            $0.selectedAxes = [.expression]
            $0.createdLink = "https://hilit.my/feedback/tok"
            $0.isLinkRecovered = true
            $0.isCompletionModalVisible = true
        }
        #expect(store.state.isAxisLocked)
    }

    @Test("409 인데 회수까지 실패하면 안내 토스트로 끝낸다")
    func alreadyExistsWithoutRecoveryFallsBackToToast() async {
        let clock = TestClock()
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.create = { _, _ in throw FeedbackShareError.alreadyExists }
            $0.feedbackShareClient.status = { _ in throw FeedbackShareError.networkFailure }
            $0.continuousClock = clock
        }

        await store.send(.view(.userToggledAxis(.gaze, isOn: true))) {
            $0.selectedAxes = [.gaze]
        }
        await store.send(.view(.userTappedCreateLink)) {
            $0.isCreating = true
        }
        await store.receive(\.inner.shareLinkFailed) {
            $0.isCreating = false
            $0.toast = "이미 만들어 둔 링크가 있어요."
        }
        await clock.advance(by: .seconds(2))
        await store.receive(\.inner.toastDismissed) {
            $0.toast = nil
        }
    }

    @Test("진입 때 활성 링크가 있으면 회수해 항목을 잠근다 — 모달은 스스로 뜨지 않는다")
    func onAppearRecoversActiveLink() async {
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.status = { _ in Self.activeStatus(axes: ["GAZE", "VOICE", "NEW_AXIS"]) }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.existingShareLoaded) {
            // 서버가 축을 늘려도 모르는 코드는 버린다.
            $0.selectedAxes = [.gaze, .voice]
            $0.createdLink = "https://hilit.my/feedback/tok"
            $0.isLinkRecovered = true
        }
        #expect(store.state.isAxisLocked)
        // 진입만으로 모달을 띄우지 않는다 — 재복사는 CTA 로 시작한다.
        #expect(!store.state.isCompletionModalVisible)
    }

    @Test("무효화·비공개 링크는 회수 대상이 아니다 — 복사해도 지인이 못 연다")
    func onAppearIgnoresInactiveLink() async {
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.status = { _ in
                FeedbackShareStatus(
                    token: "tok",
                    status: .private,
                    axes: ["GAZE"],
                    submittedCount: nil,
                    videoExpiresAt: nil,
                    requestedAt: nil
                )
            }
        }

        await store.send(.view(.onAppear))
        #expect(store.state.createdLink == nil)
        #expect(!store.state.isAxisLocked)
    }

    @Test("복사하면 클립보드에 담기고 모달이 닫히며 공유 시트가 이어진다")
    func copyPutsLinkOnPasteboardThenPresentsShareSheet() async {
        let clock = TestClock()
        let copied = LockIsolated<String?>(nil)
        var initialState = ReportPeerFeedbackFeature.State(sessionId: 7)
        initialState.createdLink = "https://hilit.my/feedback/tok"
        initialState.isCompletionModalVisible = true
        let store = TestStore(initialState: initialState) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.pasteboard = PasteboardClient { copied.setValue($0) }
            $0.continuousClock = clock
        }

        await store.send(.view(.userTappedCopyLink)) {
            $0.isCompletionModalVisible = false
            $0.toast = "링크를 복사했어요."
        }
        // 모달(cover)이 닫히는 동안엔 시트를 올리지 않는다 — 한 틱 뒤에 올라온다.
        await clock.advance(by: .milliseconds(400))
        await store.receive(\.inner.shareSheetRequested) {
            $0.isShareSheetPresented = true
        }
        await clock.advance(by: .milliseconds(1600))
        await store.receive(\.inner.toastDismissed) {
            $0.toast = nil
        }

        #expect(copied.value == "https://hilit.my/feedback/tok")
    }
}
