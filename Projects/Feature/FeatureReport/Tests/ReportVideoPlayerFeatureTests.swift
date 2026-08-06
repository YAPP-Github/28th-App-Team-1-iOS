//
//  ReportVideoPlayerFeatureTests.swift
//  FeatureReportTests
//
//  Created by EunSeo on 26/07/29.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import DomainInterviewReportTesting
import Foundation
import Testing

@testable import FeatureReportImplementation

/// 플레이어 — 컨트롤 자동 숨김·구간 이동·하이라이트 시트 연동을 고정한다.
@MainActor
struct ReportVideoPlayerFeatureTests {
    private static let videoURL = URL(string: "https://example.com/interview/1.mp4")!
    private static var cards: [InterviewReportCard] {
        InterviewReportFixtures.ready.cards ?? []
    }

    private func makeStore(
        clock: TestClock<Duration>,
        state: ReportVideoPlayerFeature.State = ReportVideoPlayerFeature.State(
            videoURL: videoURL,
            cards: cards
        )
    ) -> TestStoreOf<ReportVideoPlayerFeature> {
        TestStore(initialState: state) {
            ReportVideoPlayerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
    }

    @Test("손대지 않으면 3초 뒤 컨트롤이 숨어 영상만 남는다")
    func controlsHideAfterIdle() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("영상을 탭하면 컨트롤이 사라지고, 다시 탭하면 돌아온다")
    func surfaceTapTogglesControls() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.userTappedSurface)) {
            $0.areControlsVisible = false
        }
        await store.send(.view(.userTappedSurface)) {
            $0.areControlsVisible = true
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("일시정지 중에는 컨트롤을 숨기지 않는다 — 다시 재생할 버튼이 사라지지 않게")
    func pausedControlsStayVisible() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.onAppear))
        await store.send(.view(.userTappedPlayPause)) {
            $0.isPlaying = false
        }
        // 타이머가 취소돼 아무 액션도 오지 않는다.
        await clock.advance(by: .seconds(10))
    }

    @Test("대본을 켜면 하단 바가 대본의 일부라 화면 탭으로 숨지 않는다")
    func transcriptKeepsBottomBar() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.userTappedTranscriptToggle)) {
            $0.isTranscriptVisible = true
        }
        await store.send(.view(.userTappedSurface))
        #expect(store.state.isBottomBarVisible)
        #expect(!store.state.isPlaybackControlVisible)

        await store.send(.view(.userTappedTranscriptToggle)) {
            $0.isTranscriptVisible = false
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("좌우 화살표는 초가 아니라 진행바 한 칸(대본 구간)씩 움직인다")
    func chunkArrowsStepOneSegment() async {
        let clock = TestClock()
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.duration = 12
        state.currentTime = 5
        let store = makeStore(clock: clock, state: state)
        #expect(store.state.progressChunks.map(\.start) == [0, 3.4, 6.4, 9.1])

        // 5초는 둘째 칸(3.4~6.4) — 왼쪽 화살표는 첫 칸 시작으로.
        await store.send(.view(.userTappedPreviousChunk)) {
            $0.currentTime = 0
            $0.seekToken = 1
            $0.isSeeking = true
        }
        await store.send(.view(.userTappedNextChunk)) {
            $0.currentTime = 3.4
            $0.seekTarget = 3.4
            $0.seekToken = 2
        }
        // 셋째 칸은 둘째 카드의 첫 구간 — 대본의 «현재 줄» 도 같이 넘어간다.
        await store.send(.view(.userTappedNextChunk)) {
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 3
            $0.currentLineID = 1
        }
        await store.send(.view(.userTappedNextChunk)) {
            $0.currentTime = 9.1
            $0.seekTarget = 9.1
            $0.seekToken = 4
        }
        // 마지막 칸에선 갈 곳이 없다 — 탭이 아무 일도 하지 않는다(영상 끝으로 튀지 않게).
        await store.send(.view(.userTappedNextChunk))
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("끝까지 본 뒤 재생을 누르면 처음부터 다시 돈다")
    func playAfterEndRestarts() async {
        let clock = TestClock()
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.duration = 12
        state.currentTime = 12
        state.isPlaying = false
        let store = makeStore(clock: clock, state: state)

        await store.send(.view(.userTappedPlayPause)) {
            $0.isPlaying = true
            $0.currentTime = 0
            $0.seekTarget = 0
            $0.seekToken = 1
            $0.isSeeking = true
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("이동 직후 보고되는 이전 위치는 버린다 — 진행바가 되돌아가지 않게")
    func staleTimeUpdatesAreIgnoredWhileSeeking() async {
        let clock = TestClock()
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.duration = 12
        let store = makeStore(clock: clock, state: state)

        await store.send(.view(.userTappedChunk(index: 2))) {
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 1
            $0.isSeeking = true
            $0.currentLineID = 1
        }
        // 이동 전 위치 — 무시된다.
        await store.send(.inner(.timeUpdated(0.4)))
        // 목표에 닿았다 — 이후부터 다시 따라간다.
        await store.send(.inner(.timeUpdated(6.5))) {
            $0.isSeeking = false
            $0.currentTime = 6.5
        }
        await store.send(.inner(.timeUpdated(6.7))) {
            $0.currentTime = 6.7
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("진행바 칸을 누르면 그 구간 시작으로 이동한다")
    func chunkTapSeeksToSegmentStart() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)
        // 카드 2장의 구간을 시간축 하나로 이어 붙인다 — 3번째 칸은 두 번째 카드의 첫 구간.
        #expect(store.state.progressChunks.count == 4)

        await store.send(.view(.userTappedChunk(index: 2))) {
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 1
            $0.isSeeking = true
            $0.currentLineID = 1
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("서버 구간이 없으면 진행바는 영상 전체 한 칸으로 대체된다")
    func progressFallsBackToSingleChunk() {
        var state = ReportVideoPlayerFeature.State(
            videoURL: Self.videoURL,
            cards: [InterviewReportFixtures.lowResolutionCard]
        )
        state.duration = 30
        state.currentTime = 12

        #expect(state.progressChunks.count == 1)
        #expect(state.progressChunks[0].end == 30)
        // 칸이 하나뿐이라 왼쪽 화살표는 처음으로 되돌리고, 오른쪽은 갈 곳이 없다.
        #expect(state.previousChunkStart == 0)
        #expect(state.nextChunkStart == nil)
    }

    @Test("하이라이트를 누르면 영상이 멈추고 시트가 올라온다")
    func highlightTapPausesAndPresentsSheet() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)
        let card = Self.cards[1]

        await store.send(.view(.userTappedHighlight(cardIndex: 1, spanIndex: 0))) {
            $0.isPlaying = false
            $0.highlightDetail = ReportHighlightDetailFeature.State(
                context: HighlightContext(card: card, span: card.highlightSpans![0])!,
                showsVideoJump: true
            )
        }
        #expect(store.state.highlightDetail?.context.evidenceAt == 6.4)
        // 시트를 보는 동안 플레이어 컨트롤은 전부 비운다 — 시트 밖에 남는 X 도 포함.
        #expect(!store.state.isCloseButtonVisible)
        #expect(!store.state.isBottomBarVisible)
        #expect(!store.state.isPlaybackControlVisible)
    }

    @Test("시트의 «영상 보러가기» 는 시트를 닫고 그 장면부터 다시 재생한다")
    func videoJumpSeeksAndResumes() async {
        let clock = TestClock()
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.duration = 12
        state.isPlaying = false
        state.highlightDetail = ReportHighlightDetailFeature.State(
            context: HighlightContext(
                card: Self.cards[1],
                span: Self.cards[1].highlightSpans![0]
            )!,
            showsVideoJump: true
        )
        let store = makeStore(clock: clock, state: state)

        await store.send(.highlightDetail(.presented(.view(.userTappedVideoJump))))
        await store.receive(\.highlightDetail.presented.delegate.videoJumpRequested) {
            $0.highlightDetail = nil
            $0.isPlaying = true
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 1
            $0.isSeeking = true
            $0.currentLineID = 1
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("재생 실패는 컨트롤 대신 안내 문구로 바뀐다")
    func playbackFailureStopsControls() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.inner(.playbackFailed(
            message: ReportVideoPlayerFeature.playbackFailureMessage
        ))) {
            $0.playbackFailureMessage = ReportVideoPlayerFeature.playbackFailureMessage
            $0.isPlaying = false
        }
        #expect(!store.state.isPlaybackControlVisible)
        #expect(!store.state.isBottomBarVisible)
    }

    @Test("«다시 시도» 는 안내를 걷고 플레이어 재생성을 명령한다")
    func playbackRetryRebuildsPlayer() async {
        let clock = TestClock()
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.playbackFailureMessage = ReportVideoPlayerFeature.playbackFailureMessage
        state.isPlaying = false
        let store = makeStore(clock: clock, state: state)

        await store.send(.view(.userTappedPlaybackRetry)) {
            $0.playbackFailureMessage = nil
            // 뷰는 이 토큰 변화만 보고 AVPlayer 를 새로 만든다 — 리듀서는 플레이어를 갖지 않는다.
            $0.reloadToken = 1
            $0.isPlaying = true
        }
        #expect(store.state.isPlaybackControlVisible)
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("X 는 리포트로 돌아간다")
    func backRequestPropagates() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
    }
}
