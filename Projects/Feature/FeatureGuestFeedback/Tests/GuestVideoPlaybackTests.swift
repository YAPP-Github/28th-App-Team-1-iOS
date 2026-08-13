//
//  GuestVideoPlaybackTests.swift
//  FeatureGuestFeedbackTests
//
//  Created by 서정원 on 26/08/13.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import Foundation
import Testing
@testable import FeatureGuestFeedbackImplementation

/// 재생 컨트롤 규약 — 리포트 플레이어와 같은 동작인지 본다(탭→컨트롤·3초 자동 숨김·칸 단위 이동).
@MainActor
struct GuestVideoPlaybackTests {
    private func makeStore(
        clock: TestClock<Duration> = TestClock(),
        boundaries: [QuestionBoundary] = [
            QuestionBoundary(turnLevel: 1, startAt: 0, questionText: "자기소개"),
            QuestionBoundary(turnLevel: 2, startAt: 40, questionText: "협업 경험")
        ],
        duration: TimeInterval = 100
    ) -> TestStoreOf<GuestVideoPlaybackFeature> {
        var state = GuestVideoPlaybackFeature.State()
        state.videoURL = URL(string: "https://example.com/interview.mp4")
        state.boundaries = boundaries
        state.duration = duration
        state.isPrepared = true
        state.isPlaying = true
        return TestStore(initialState: state) {
            GuestVideoPlaybackFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
    }

    @Test("영상을 탭하면 컨트롤이 숨었다 나오고, 띄운 뒤 3초면 저절로 사라진다")
    func surfaceTapTogglesControlsAndTheyAutoHide() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        // 처음엔 떠 있다 — 탭은 끄는 쪽.
        await store.send(.view(.userTappedSurface)) { $0.areControlsVisible = false }
        await store.send(.view(.userTappedSurface)) { $0.areControlsVisible = true }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) { $0.areControlsVisible = false }
    }

    @Test("멈추면 컨트롤을 숨기지 않는다 — 다시 재생할 방법이 사라진다")
    func pauseKeepsControlsVisible() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.userTappedPlayPause)) {
            $0.isPlaying = false
            $0.areControlsVisible = true
        }
        // 타이머가 취소됐으므로 3초가 지나도 아무 일이 없다.
        await clock.advance(by: .seconds(3))
        #expect(store.state.areControlsVisible)
    }

    @Test("진행바 칸을 누르면 그 질문 시작으로 이동한다 — 이동 수단은 이것 하나뿐이다")
    func chunkTapSeeksToQuestionStart() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        // 둘째 질문 칸(turnLevel 2) 탭 → 40초.
        await store.send(.view(.userTappedChunk(index: 2))) {
            $0.seekTarget = 40
            $0.seekToken = 1
            $0.currentTime = 40
            $0.isSeeking = true
            $0.areControlsVisible = true
        }
        // 이동이 목표에 닿기 전 보고는 버린다 — 진행바가 눌렀던 자리에서 되돌아가지 않게.
        await store.send(.inner(.timeUpdated(12)))
        await store.send(.inner(.timeUpdated(40.1))) {
            $0.isSeeking = false
            $0.currentTime = 40.1
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) { $0.areControlsVisible = false }
    }

    @Test("질문 경계가 없으면 진행바는 한 칸이고, 그 칸은 눌러도 되감기지 않는다")
    func fallbackChunkIsNotSeekable() async {
        let store = makeStore(boundaries: [])

        #expect(store.state.hasQuestionSections == false)
        #expect(store.state.progressChunks.count == 1)
        // 대체 칸 id(0) 을 눌러도 아무 일이 없다 — 바 아무 데나 눌렀다고 처음으로 되감기면 사고다.
        await store.send(.view(.userTappedChunk(index: 0)))
    }

    @Test("끝까지 본 뒤 재생을 누르면 처음부터 다시 튼다")
    func playAfterEndRestartsFromZero() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)
        await store.send(.inner(.timeUpdated(100))) { $0.currentTime = 100 }
        await store.send(.inner(.playbackFinished)) {
            $0.isPlaying = false
            $0.areControlsVisible = true
        }

        await store.send(.view(.userTappedPlayPause)) {
            $0.seekTarget = 0
            $0.seekToken = 1
            $0.currentTime = 0
            $0.isSeeking = true
            $0.isPlaying = true
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) { $0.areControlsVisible = false }
    }

    @Test("영상이 열리지 않으면 실패 문구를 걸고, 그래도 준비 종결은 부모에게 알린다")
    func unplayableVideoStillReportsPrepareFinished() async {
        var state = GuestVideoPlaybackFeature.State()
        state.videoURL = URL(string: "https://example.com/expired.mp4")
        let store = TestStore(initialState: state) {
            GuestVideoPlaybackFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.videoPrepareFinished(isPlayable: false))) {
            $0.isPrepared = true
            $0.playbackFailureMessage = GuestVideoPlaybackFeature.playbackFailureMessage
        }
        await store.receive(\.delegate.prepareFinished)
    }

    @Test("재시도가 또 실패하면 실패 문구가 다시 선다 — 재시도 버튼이 사라지면 안 된다")
    func retryFailureRestoresFailureMessage() async {
        let clock = TestClock()
        var state = GuestVideoPlaybackFeature.State()
        state.videoURL = URL(string: "https://example.com/expired.mp4")
        state.isPrepared = true
        state.playbackFailureMessage = GuestVideoPlaybackFeature.playbackFailureMessage
        let store = TestStore(initialState: state) {
            GuestVideoPlaybackFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        // «다시 시도» — 안내를 걷고 플레이어 재생성을 명령한다.
        await store.send(.view(.userTappedPlaybackRetry)) {
            $0.playbackFailureMessage = nil
            $0.reloadToken = 1
            $0.isPlaying = true
            $0.areControlsVisible = true
        }
        // 그 재시도가 또 실패 — 안내가 다시 서고, 재생 중 표시는 내려간다.
        await store.send(.view(.videoPrepareFinished(isPlayable: false))) {
            $0.playbackFailureMessage = GuestVideoPlaybackFeature.playbackFailureMessage
            $0.isPlaying = false
        }
        await store.receive(\.delegate.prepareFinished)
    }

    @Test("재시도가 성공하면 실패 문구가 걷힌다")
    func retrySuccessClearsFailureMessage() async {
        var state = GuestVideoPlaybackFeature.State()
        state.videoURL = URL(string: "https://example.com/interview.mp4")
        state.isPrepared = true
        state.playbackFailureMessage = GuestVideoPlaybackFeature.playbackFailureMessage
        state.isPlaying = true
        let store = TestStore(initialState: state) {
            GuestVideoPlaybackFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.videoPrepareFinished(isPlayable: true))) {
            $0.playbackFailureMessage = nil
        }
        await store.receive(\.delegate.prepareFinished)
    }

    @Test("영상 URL 자체가 없으면 실패가 아니라 «아직 없음» 이라 문구를 걸지 않는다")
    func missingVideoIsNotAFailure() async {
        let store = TestStore(initialState: GuestVideoPlaybackFeature.State()) {
            GuestVideoPlaybackFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.videoPrepareFinished(isPlayable: false))) { $0.isPrepared = true }
        await store.receive(\.delegate.prepareFinished)
        #expect(store.state.playbackFailureMessage == nil)
    }
}
