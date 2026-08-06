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

    @Test("자동 숨김은 딤·재생 컨트롤만 걷는다 — 진행바·대본 버튼은 붙박이")
    func bottomBarSurvivesAutoHide() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
        #expect(!store.state.isPlaybackControlVisible)
        #expect(store.state.isBottomBarVisible)
        #expect(store.state.isBottomScrimVisible)
    }

    @Test("«이전 화면으로 가기» 는 시트로 들어온 판에만 있고, X 와 달리 시트로 돌아간다")
    func returnToPreviousOnlyForSheetEntry() async {
        let clock = TestClock()
        #expect(!makeStore(clock: clock).state.isReturnToPreviousVisible)

        let store = makeStore(clock: clock, state: ReportVideoPlayerFeature.State(
            videoURL: Self.videoURL,
            cards: Self.cards,
            entry: .highlightSheet
        ))
        #expect(store.state.isReturnToPreviousVisible)

        await store.send(.view(.userTappedReturnToPrevious))
        await store.receive(\.delegate.returnToHighlightSheetRequested)

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
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

    @Test("대본을 켜 두면 화면 탭이 딤·재생 컨트롤을 만지지 않는다 (하단 바는 그대로)")
    func transcriptSwallowsSurfaceTap() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.view(.userTappedTranscriptToggle)) {
            $0.isTranscriptVisible = true
        }
        await store.send(.view(.userTappedSurface))
        #expect(store.state.isBottomBarVisible)
        #expect(!store.state.isPlaybackControlVisible)
        // 대본 오버레이가 제 스크림을 갖고 있어 하단 스크림은 겹쳐 깔지 않는다.
        #expect(!store.state.isBottomScrimVisible)

        await store.send(.view(.userTappedTranscriptToggle)) {
            $0.isTranscriptVisible = false
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("좌우 화살표는 초가 아니라 진행바 한 칸(질문 턴)씩 움직인다")
    func chunkArrowsStepOneTurn() async {
        let clock = TestClock()
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.duration = 12
        state.currentTime = 5
        let store = makeStore(clock: clock, state: state)
        // 칸 하나 = 카드(질문 턴) 하나 — 발화 단위가 아니다(잘게 쪼개지지 않는다).
        #expect(store.state.progressChunks.map(\.start) == [0, 6.4])

        // 5초는 첫 칸(0~6.4) 안 — 왼쪽 화살표는 그 칸을 다시 처음부터.
        await store.send(.view(.userTappedPreviousChunk)) {
            $0.currentTime = 0
            $0.seekToken = 1
            $0.isSeeking = true
        }
        // 다음 칸은 둘째 카드 턴 — 오버레이 대본도 그 턴 첫 문장으로 넘어간다.
        await store.send(.view(.userTappedNextChunk)) {
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 2
            $0.transcriptPosition = VideoTranscript.Position(lineID: 1, sentenceIndex: 0)
        }
        // 마지막 칸에선 갈 곳이 없다 — 탭이 아무 일도 하지 않는다(영상 끝으로 튀지 않게).
        await store.send(.view(.userTappedNextChunk))
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.controlsHideElapsed) {
            $0.areControlsVisible = false
        }
    }

    @Test("대본은 면접관 질문까지 시각 순으로 담는다 — 질문 오프셋으로 답변을 자르지 않는다")
    func transcriptIncludesInterviewerTurns() {
        let state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        let line = state.transcript.line(with: 0)

        // 턴 = 질문 → 답변. 질문이 첫 문장이라 순번 0 이다.
        #expect(line?.sentences.map(\.role) == [.interviewer, .interviewee, .interviewee])
        // 면접관 오프셋(0..<26)은 질문 문자열 기준 — 답변 대본에 대고 자르면 다른 문장이 나온다.
        #expect(line?.sentences.first?.text == Self.cards[0].questionText)
        #expect(line?.sentences.first?.spans.isEmpty == true)
        // 하이라이트는 답변에만 붙는다.
        #expect(line?.sentences[1].spans.isEmpty == false)

        // 질문이 재생되는 동안 오버레이는 그 턴 질문 문장에 선다.
        #expect(state.transcript.position(at: 0.5) == VideoTranscript.Position(lineID: 0, sentenceIndex: 0))
        #expect(state.transcript.position(at: 2) == VideoTranscript.Position(lineID: 0, sentenceIndex: 1))
        #expect(state.transcript.position(at: 6.5) == VideoTranscript.Position(lineID: 1, sentenceIndex: 0))
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

        await store.send(.view(.userTappedChunk(index: 1))) {
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 1
            $0.isSeeking = true
            $0.transcriptPosition = VideoTranscript.Position(lineID: 1, sentenceIndex: 0)
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

    @Test("진행바 칸을 누르면 그 턴 시작으로 이동한다")
    func chunkTapSeeksToTurnStart() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)
        // 칸 하나 = 카드(질문 턴) 하나 — 카드 2장이면 칸 2개.
        #expect(store.state.progressChunks.count == 2)

        await store.send(.view(.userTappedChunk(index: 1))) {
            $0.currentTime = 6.4
            $0.seekTarget = 6.4
            $0.seekToken = 1
            $0.isSeeking = true
            $0.transcriptPosition = VideoTranscript.Position(lineID: 1, sentenceIndex: 0)
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

    @Test("대본이 없으면 토글도 없고 하단 스크림이 그대로 남는다 — 빈 오버레이로 레이아웃이 틀어지지 않게")
    func noTranscriptKeepsLayout() async {
        let clock = TestClock()
        let store = makeStore(clock: clock, state: ReportVideoPlayerFeature.State(
            videoURL: Self.videoURL,
            cards: [InterviewReportFixtures.lowResolutionCard]
        ))

        #expect(!store.state.hasTranscript)
        // 버튼이 없어 눌릴 일이 없지만, 신호가 와도 상태를 만지지 않는다.
        await store.send(.view(.userTappedTranscriptToggle))
        #expect(!store.state.isTranscriptOverlayVisible)
        #expect(store.state.isBottomScrimVisible)
        #expect(store.state.isPlaybackControlVisible)
    }

    @Test("대본을 켜도 첫 발화 앞에서는 오버레이를 얹지 않는다 — 글자 없는 스크림이 화면을 덮지 않게")
    func transcriptOverlayWaitsForFirstSentence() {
        var state = ReportVideoPlayerFeature.State(videoURL: Self.videoURL, cards: Self.cards)
        state.isTranscriptVisible = true
        state.transcriptPosition = nil

        #expect(state.hasTranscript)
        #expect(!state.isTranscriptOverlayVisible)
        #expect(state.isBottomScrimVisible)
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
                // 이미 영상 안이라 «영상 보러가기» 는 없다.
                showsVideoJump: false
            )
        }
        // 6.4 는 그 턴 면접관 질문 시작 — 하이라이트는 답변 구간이라 7.2 다.
        #expect(store.state.highlightDetail?.context.evidenceAt == 7.2)
        // 시트를 보는 동안 플레이어 컨트롤은 전부 비운다 — 시트 밖에 남는 X 도 포함.
        #expect(!store.state.isCloseButtonVisible)
        #expect(!store.state.isBottomBarVisible)
        #expect(!store.state.isPlaybackControlVisible)
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
