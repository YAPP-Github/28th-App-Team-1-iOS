//
//  GuestFeedbackEntryFlowTests.swift
//  FeatureGuestFeedbackTests
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import DomainGuestFeedbackTesting
import Foundation
import Testing
@testable import FeatureGuestFeedbackImplementation

@MainActor
struct GuestFeedbackEntryFlowTests {
    private func makeStore(
        clock: any Clock<Duration> = ImmediateClock(),
        entry: GuestFeedbackEntry = .fixture(),
        localStore: GuestFeedbackLocalStore = .inMemory()
    ) -> TestStoreOf<GuestFeedbackFeature> {
        TestStore(initialState: GuestFeedbackFeature.State(token: "t1")) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = .mock(entry: entry)
            $0.guestFeedbackLocalStore = localStore
            $0.continuousClock = clock
        }
    }

    /// entry 가 도착하면 재생 재료(영상 URL·질문 경계)가 함께 자식 State 로 넘어간다 — 게이트와 무관하다.
    private func expectPlaybackMaterial(
        _ state: inout GuestFeedbackFeature.State,
        from entry: GuestFeedbackEntry = .fixture()
    ) {
        state.playback.videoURL = entry.videoURL
        state.playback.boundaries = entry.questionBoundaries ?? []
    }

    @Test("OPEN 게이트면 온보딩으로 진입한다")
    func openGateLandsOnOnboarding() async {
        let store = makeStore()

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
            expectPlaybackMaterial(&$0)
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
            expectPlaybackMaterial(&$0)
            $0.playback.isPlaying = true   // 시작 연출을 건너뛴 진입이라 바로 튼다
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
            expectPlaybackMaterial(&$0, from: entry)
            $0.playback.isPlaying = true
        }
        #expect(store.state.canEvaluate == false)
        #expect(store.state.isSubmitEnabled == false)
    }

    @Test(
        "차단 게이트는 사유별 차단 화면으로 간다",
        arguments: [
            (GuestFeedbackGate.private, GuestFeedbackFeature.GateReason.private),
            (GuestFeedbackGate.expired, GuestFeedbackFeature.GateReason.expired),
            (GuestFeedbackGate.alreadySubmitted, GuestFeedbackFeature.GateReason.alreadySubmitted)
        ]
    )
    func closedGatesLandOnGateScreen(gate: GuestFeedbackGate, reason: GuestFeedbackFeature.GateReason) async {
        let entry = GuestFeedbackEntry.fixture(gate: gate, submissionOpen: false)
        let store = makeStore(entry: entry)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = entry
            $0.phase = .gateClosed(reason)
            expectPlaybackMaterial(&$0, from: entry)
        }
    }

    @Test("유효하지 않은 토큰이면 차단 화면으로 간다")
    func invalidTokenLandsOnGateScreen() async {
        var client = GuestFeedbackClient.mock()
        client.entry = { _, _ in throw GuestFeedbackError.tokenNotFound }
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
            (GuestFeedbackError.shareClosed, GuestFeedbackFeature.GateReason.private),
            (GuestFeedbackError.alreadySubmitted, GuestFeedbackFeature.GateReason.alreadySubmitted),
            (GuestFeedbackError.capacityFull, GuestFeedbackFeature.GateReason.unknown)
        ]
    )
    func permanentEnterErrorsLandOnGateScreen(error: GuestFeedbackError, reason: GuestFeedbackFeature.GateReason) async {
        var client = GuestFeedbackClient.mock()
        client.entry = { _, _ in throw error }
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
            expectPlaybackMaterial(&$0)
        }
        // 시작 → 온보딩 위 닉네임 시트 표출(phase 는 온보딩 유지).
        await store.send(.view(.startTapped)) { $0.isEnteringNickname = true }
        // 닉네임 확정 → 시트 닫고 시작 연출로.
        await store.send(.view(.nicknameNextTapped)) {
            $0.isEnteringNickname = false
            $0.phase = .starting
        }
        await store.receive(\.inner.draftSaved)   // 닉네임 확정 시점 즉시 저장
        // 최소 노출만으론 안 넘어간다 — 영상 준비 보고가 아직 없어 오버레이가 남는다.
        await store.receive(\.inner.startingCueElapsed) { $0.isStartingCueElapsed = true }
        // 뷰의 영상 준비 종결 보고가 오면 그때 평가로.
        await store.send(.playback(.view(.videoPrepareFinished(isPlayable: true)))) {
            $0.playback.isPrepared = true
        }
        await store.receive(\.playback.delegate.prepareFinished) {
            $0.isVideoPrepared = true
            $0.phase = .evaluating
            $0.startedEvaluation = true
            $0.activeAxis = AttitudeAxis.allFive[0]
            $0.playback.isPlaying = true
        }
        await store.receive(\.inner.draftSaved)   // 평가 진입(startedEvaluation) 저장
        await store.finish()
    }

    @Test("영상이 먼저 준비돼도 시작 연출 최소 노출 전에는 평가로 넘어가지 않는다")
    func earlyVideoPrepareWaitsForStartingCue() async {
        // 준비 보고가 연출보다 먼저 오는 순서를 만들려면 시계를 손으로 밀어야 한다.
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
            expectPlaybackMaterial(&$0)
        }
        await store.send(.view(.startTapped)) { $0.isEnteringNickname = true }
        await store.send(.view(.nicknameNextTapped)) {
            $0.isEnteringNickname = false
            $0.phase = .starting
        }
        await store.receive(\.inner.draftSaved)
        // 준비 보고가 먼저 — phase 는 starting 에 머문다(문구가 깜빡이지 않게).
        await store.send(.playback(.view(.videoPrepareFinished(isPlayable: true)))) {
            $0.playback.isPrepared = true
        }
        await store.receive(\.playback.delegate.prepareFinished) { $0.isVideoPrepared = true }
        await clock.advance(by: .seconds(1))
        await store.receive(\.inner.startingCueElapsed) {
            $0.isStartingCueElapsed = true
            $0.phase = .evaluating
            $0.startedEvaluation = true
            $0.activeAxis = AttitudeAxis.allFive[0]
            $0.playback.isPlaying = true
        }
        await store.receive(\.inner.draftSaved)
        await store.finish()
    }

    @Test("닉네임 시트를 스와이프로 닫으면 온보딩에 머물러 재진입할 수 있다")
    func nicknameSheetDismissKeepsOnboarding() async {
        let store = makeStore()

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.entry = .fixture()
            $0.phase = .onboarding
            expectPlaybackMaterial(&$0)
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
        client.entry = { _, _ in
            attempts.withValue { $0 += 1 }
            if attempts.value == 1 {
                throw GuestFeedbackError.networkFailure
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
            expectPlaybackMaterial(&$0)
        }
    }

    @Test("닫기 요청은 어느 phase 에서든 부모에게 dismissed 를 알린다")
    func closeNotifiesParent() async {
        let store = makeStore()

        // onAppear 없이 즉시 탭 — loading phase 에서도 탈출구가 열려 있어야 한다.
        await store.send(.view(.closeTapped))
        await store.receive(\.delegate.dismissed)
    }
}
