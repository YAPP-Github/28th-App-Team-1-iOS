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
            $0.createdLink = "https://hilit.app/feedback/tok"
        }

        #expect(sent.value == ["GAZE", "VOICE"])
    }

    @Test("항목을 하나도 안 고르면 요청하지 않고 안내만 띄운다")
    func emptySelectionDoesNotCallServer() async {
        let clock = TestClock()
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            // create 는 testValue(unimplemented) 그대로 — 호출되면 테스트가 실패한다.
            $0.continuousClock = clock
        }

        await store.send(.view(.userTappedCreateLink)) {
            $0.toast = "평가받을 항목을 하나 이상 골라주세요."
        }
        await clock.advance(by: .seconds(2))
        await store.receive(\.inner.toastDismissed) {
            $0.toast = nil
        }
    }

    @Test("생성 실패는 사용자 문구로 바뀌고 CTA 가 다시 눌린다")
    func failureSurfacesMessageAndUnlocksCTA() async {
        let clock = TestClock()
        let store = TestStore(initialState: ReportPeerFeedbackFeature.State(sessionId: 7)) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.feedbackShareClient.create = { _, _ in throw FeedbackShareError.alreadyExists }
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

    @Test("복사하면 클립보드에 링크가 담기고 모달이 닫힌다")
    func copyPutsLinkOnPasteboardAndClosesModal() async {
        let clock = TestClock()
        let copied = LockIsolated<String?>(nil)
        var initialState = ReportPeerFeedbackFeature.State(sessionId: 7)
        initialState.createdLink = "https://hilit.app/feedback/tok"
        let store = TestStore(initialState: initialState) {
            ReportPeerFeedbackFeature()
        } withDependencies: {
            $0.pasteboard = PasteboardClient { copied.setValue($0) }
            $0.continuousClock = clock
        }

        await store.send(.view(.userTappedCopyLink)) {
            $0.createdLink = nil
            $0.toast = "링크를 복사했어요."
        }
        await clock.advance(by: .seconds(2))
        await store.receive(\.inner.toastDismissed) {
            $0.toast = nil
        }

        #expect(copied.value == "https://hilit.app/feedback/tok")
    }
}
