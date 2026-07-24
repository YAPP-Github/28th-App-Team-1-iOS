//
//  GuestFeedbackEntryFlowTests.swift
//  FeatureGuestFeedbackTests
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainFeedbackInterface
import DomainFeedbackTesting
import Foundation
import Testing
@testable import FeatureGuestFeedbackImplementation

@MainActor
struct GuestFeedbackEntryFlowTests {
    private func makeStore(
        entry: GuestFeedbackEntry = .fixture(),
        localStore: GuestFeedbackLocalStore = .inMemory()
    ) -> TestStoreOf<GuestFeedbackFeature> {
        TestStore(initialState: GuestFeedbackFeature.State(token: "t1")) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = .mock(entry: entry)
            $0.guestFeedbackLocalStore = localStore
            $0.continuousClock = ImmediateClock()
        }
    }

    @Test("OPEN 게이트면 온보딩으로 진입한다")
    func openGateLandsOnOnboarding() async {
        let store = makeStore()

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
        }
    }

    @Test("임시저장분이 있으면 복원하고 평가 화면으로 직행한다")
    func draftRestoresAndSkipsOnboarding() async {
        let draft = GuestFeedbackDraft(
            nickname: "민지",
            ratings: ["GAZE": RatingDraft(level: 2, comment: "가끔 피해요")],
            overallFeedback: "좋았어요",
            startedEvaluation: true
        )
        let localStore = GuestFeedbackLocalStore.inMemory()
        localStore.saveDraft("t1", draft)
        let store = makeStore(localStore: localStore)

        await store.send(.view(.onAppear)) {
            $0.nickname = "민지"
            $0.ratings = ["GAZE": RatingDraft(level: 2, comment: "가끔 피해요")]
            $0.overallFeedback = "좋았어요"
            $0.startedEvaluation = true
        }
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .evaluating
            $0.activeAxis = AttitudeAxis.allFive[0]
        }
    }

    @Test("FULL 게이트면 시청 전용 평가 화면으로 간다")
    func fullGateIsViewingOnly() async {
        let entry = GuestFeedbackEntry.fixture(gate: .full, submissionOpen: false)
        let store = makeStore(entry: entry)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = entry
            $0.phase = .evaluating
            $0.activeAxis = AttitudeAxis.allFive[0]
        }
        #expect(store.state.canEvaluate == false)
        #expect(store.state.isSubmitEnabled == false)
    }

    @Test(
        "차단 게이트는 사유별 차단 화면으로 간다",
        arguments: [
            (GuestFeedbackGate.private, GuestFeedbackFeature.GateReason.private),
            (GuestFeedbackGate.expired, GuestFeedbackFeature.GateReason.expired),
            (GuestFeedbackGate.alreadySubmitted, GuestFeedbackFeature.GateReason.alreadySubmitted),
            (GuestFeedbackGate.unknown, GuestFeedbackFeature.GateReason.unknown)
        ]
    )
    func closedGatesLandOnGateScreen(gate: GuestFeedbackGate, reason: GuestFeedbackFeature.GateReason) async {
        let entry = GuestFeedbackEntry.fixture(gate: gate, submissionOpen: false)
        let store = makeStore(entry: entry)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = entry
            $0.phase = .gateClosed(reason)
        }
    }

    @Test("유효하지 않은 토큰이면 차단 화면으로 간다")
    func invalidTokenLandsOnGateScreen() async {
        var client = GuestFeedbackClient.mock()
        client.enter = { _ in throw GuestFeedbackError.invalidToken }
        let store = TestStore(initialState: GuestFeedbackFeature.State(token: "t1")) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = client
            $0.guestFeedbackLocalStore = .inMemory()
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.phase = .gateClosed(.invalidToken)
        }
    }

    @Test(
        "진입 실패의 영구 도메인 에러는 재시도 알럿이 아니라 차단 화면으로 간다",
        arguments: [
            (GuestFeedbackError.closed, GuestFeedbackFeature.GateReason.private),
            (GuestFeedbackError.alreadySubmitted, GuestFeedbackFeature.GateReason.alreadySubmitted),
            (GuestFeedbackError.capacityFull, GuestFeedbackFeature.GateReason.unknown)
        ]
    )
    func permanentEnterErrorsLandOnGateScreen(error: GuestFeedbackError, reason: GuestFeedbackFeature.GateReason) async {
        var client = GuestFeedbackClient.mock()
        client.enter = { _ in throw error }
        let store = TestStore(initialState: GuestFeedbackFeature.State(token: "t1")) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = client
            $0.guestFeedbackLocalStore = .inMemory()
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.phase = .gateClosed(reason)
        }
        await store.finish()   // alreadySubmitted 의 clearDraft effect 드레인
    }

    @Test("온보딩에서 시작하면 닉네임 시트·시작 연출을 거쳐 평가로 간다")
    func onboardingLeadsToEvaluationViaNicknameAndStarting() async {
        let store = makeStore()

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
        }
        // 시작 → 온보딩 위 닉네임 시트 표출(phase 는 온보딩 유지).
        await store.send(.view(.startTapped)) { $0.isEnteringNickname = true }
        // 닉네임 확정 → 시트 닫고 시작 연출로.
        await store.send(.view(.nicknameNextTapped)) {
            $0.isEnteringNickname = false
            $0.phase = .starting
        }
        await store.receive(\.inner.draftSaved)   // 닉네임 확정 시점 즉시 저장
        await store.receive(\.inner.videoReady) {
            $0.phase = .evaluating
            $0.startedEvaluation = true
            $0.activeAxis = AttitudeAxis.allFive[0]
        }
        await store.receive(\.inner.draftSaved)   // 평가 진입(startedEvaluation) 저장
        await store.finish()
    }

    @Test("닉네임 시트를 스와이프로 닫으면 온보딩에 머물러 재진입할 수 있다")
    func nicknameSheetDismissKeepsOnboarding() async {
        let store = makeStore()

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
        }
        await store.send(.view(.startTapped)) { $0.isEnteringNickname = true }
        await store.send(.view(.nicknameSheetDismissed)) { $0.isEnteringNickname = false }
        #expect(store.state.phase == .onboarding)   // phase 는 온보딩 유지 — 다시 열 수 있다
        // 재진입 가능 확인
        await store.send(.view(.startTapped)) { $0.isEnteringNickname = true }
    }

    @Test("네트워크 실패면 알럿을 띄우고 다시 시도로 재진입한다")
    func networkFailureAlertsAndRetries() async {
        let attempts = LockIsolated(0)
        var client = GuestFeedbackClient.mock()
        client.enter = { _ in
            attempts.withValue { $0 += 1 }
            if attempts.value == 1 {
                throw GuestFeedbackError.underlying(message: "네트워크 연결을 확인해 주세요.")
            }
            return .fixture()
        }
        let store = TestStore(initialState: GuestFeedbackFeature.State(token: "t1")) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = client
            $0.guestFeedbackLocalStore = .inMemory()
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.alert = .enterFailed(message: "네트워크 연결을 확인해 주세요.")
        }
        await store.send(.alert(.presented(.retryEnter))) {
            $0.alert = nil
        }
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
        }
    }
}
