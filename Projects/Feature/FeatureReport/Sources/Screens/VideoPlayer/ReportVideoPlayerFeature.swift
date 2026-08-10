//
//  ReportVideoPlayerFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import Foundation

// @lat: [[report#영상 플레이어]]
/// 영상 플레이어 — 리포트의 종속 화면. «영상 다시보기»(처음부터) 또는 «이 장면 영상으로 보기»(해당 시각)로 진입.
///
/// **AVPlayer 는 State 에 두지 않는다** — 선례 `GuestVideoPlayerView`(FeatureGuestFeedback)대로
/// View-local `@State` 가 소유한다. 대신 재생 여부·현재 시각은 리듀서가 갖는다: 컨트롤 자동 숨김,
/// 진행바 칸 채움, 대본 오버레이의 «현재 문장» 이 모두 시각에 딸린 화면 상태라서 State 없이 못 만든다.
/// 뷰로 내리는 이동 명령은 `seekToken`(단조 증가) + `seekTarget` 쌍 — 뷰가 토큰 변화만 보고 seek 한다.
///
/// **만료 판정은 여기 책임이 아니다** — 리포트가 `playableVideoURL` 로 걸러 만료면 진입 자체가 없다.
/// 이 화면은 재생 실패(네트워크·코덱)만 표시한다.
@Reducer
public struct ReportVideoPlayerFeature {
    /// 컨트롤 자동 숨김까지 기다리는 시간. 손대지 않으면 영상만 남는다.
    static let controlsHideDelay: Duration = .seconds(3)
    /// 이동이 «닿았다» 고 보는 오차(초) — AVPlayer 보고 간격(0.2초)보다 넉넉하게.
    static let seekSettleTolerance: TimeInterval = 0.3
    /// 재생 실패 문구 — 만료가 아니라 전송·디코딩 실패다.
    static let playbackFailureMessage = "영상을 재생할 수 없어요.\n잠시 후 다시 시도해 주세요."

    /// 어디서 들어왔는가 — 화면은 한 벌이고 하단 «이전 화면으로 가기» 노출만 가른다
    /// (Figma 443:7828 은 시트 진입 판, 443:7804 는 메인 진입 판).
    public enum Entry: Equatable, Sendable {
        /// 하이라이트 상세 시트의 «영상 보러가기» — 하단에 «이전 화면으로 가기» 를 둔다.
        /// 그 버튼은 왔던 시트까지 되돌린다(상단 X 는 리포트 메인까지만).
        case highlightSheet
        /// 메인 CTA «영상 다시보기» — 하단 버튼 없이 상단 X 만.
        case reportMain
    }

    @ObservableState
    public struct State: Equatable {
        public let videoURL: URL
        /// 진입 시 이동할 시각(초). nil 이면 처음부터.
        public let startAt: TimeInterval?
        /// STT 오버레이·하이라이트 시트 재료.
        public let cards: [InterviewReportCard]
        /// 진입 경로 — 하단 «이전 화면으로 가기» 노출만 가른다.
        public let entry: Entry
        /// 카드·타임라인에서 펼친 대본 (파생값 — 입력이 바뀌지 않으니 한 번만 만든다).
        let transcript: VideoTranscript
        public var isPlaying = true
        /// AVPlayer 가 알려주는 현재 재생 시각(초).
        public var currentTime: TimeInterval = 0
        /// AVPlayer 가 알려주는 전체 길이(초). 모르면 0.
        public var duration: TimeInterval = 0
        /// 컨트롤(딤·재생 버튼) 표시 여부 — 무입력 3초 후 숨는다.
        /// **하단 바(진행바·대본 버튼)는 여기 걸리지 않는다** — 항상 떠 있다(`isBottomBarVisible`).
        public var areControlsVisible = true
        /// 대본 오버레이 표시 여부.
        public var isTranscriptVisible = false
        /// 재생 실패 — 표시할 문구를 동봉한다.
        public var playbackFailureMessage: String?
        /// 플레이어 재생성 명령 일련번호 — 뷰가 값 변화를 보고 AVPlayer 를 통째로 새로 만든다.
        /// 실패한 AVPlayer 는 `play()` 로 되살아나지 않고, 플레이어는 뷰 소유라 리듀서가 못 만진다
        /// (`seekToken` 과 같은 방식의 명령 전달).
        public var reloadToken = 0
        /// 뷰가 실행할 이동 목표(초).
        public var seekTarget: TimeInterval = 0
        /// 이동 명령 일련번호. 같은 시각으로 두 번 이동해도 뷰가 알아채게 한다.
        public var seekToken = 0
        /// 이동 중 — 목표에 닿기 전 보고되는 이전 위치를 버리기 위한 표식.
        public var isSeeking = false
        /// 지금 재생이 닿은 대본 위치(턴 + 문장). 시각에서 파생되지만 **State 에 둔다** —
        /// 매 0.2초 시각 갱신마다 오버레이 전체를 다시 그리지 않게, 문장이 바뀔 때만 값이 변하게.
        var transcriptPosition: VideoTranscript.Position?
        @Presents public var highlightDetail: ReportHighlightDetailFeature.State?

        public init(
            videoURL: URL,
            startAt: TimeInterval? = nil,
            cards: [InterviewReportCard] = [],
            entry: Entry = .reportMain
        ) {
            self.videoURL = videoURL
            self.startAt = startAt
            self.cards = cards
            self.entry = entry
            self.transcript = VideoTranscript(cards: cards)
            self.currentTime = startAt ?? 0
            self.transcriptPosition = transcript.position(at: currentTime)
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case highlightDetail(PresentationAction<ReportHighlightDetailFeature.Action>)

        public enum View: Equatable, Sendable {
            case onAppear
            /// 좌상단 X — 플레이어를 닫고 리포트로 돌아간다 (Figma 는 버튼 하나뿐).
            case userTappedBack
            /// 하단 «이전 화면으로 가기» — 시트 진입 판에만 있고, X 와 달리 왔던 상세 시트까지 되돌린다.
            case userTappedReturnToPrevious
            /// 영상 아무 곳 — 컨트롤 표시 토글.
            case userTappedSurface
            case userTappedPlayPause
            /// 재생 실패 안내의 «다시 시도» — 플레이어를 새로 만들어 보던 시각부터 다시 건다.
            // TODO(prd-외): PRD 에 재생 실패 UX 가 없어 관례(재시도 버튼)로 메운 재량 구현 — 시안 나오면 재검토.
            case userTappedPlaybackRetry
            /// 왼쪽 화살표 — 진행바 한 칸(질문 턴) 되돌리기. 초 단위가 아니다.
            case userTappedPreviousChunk
            /// 오른쪽 화살표 — 진행바 한 칸(질문 턴) 앞으로.
            case userTappedNextChunk
            /// 하단 아이콘 — 대본 오버레이 토글.
            case userTappedTranscriptToggle
            /// 진행바 칸 — 그 턴 시작으로 이동.
            case userTappedChunk(index: Int)
            /// 오버레이 대본의 하이라이트 탭.
            case userTappedHighlight(cardIndex: Int, spanIndex: Int)
        }

        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// AVPlayer 주기 관찰 결과.
            case timeUpdated(TimeInterval)
            /// 전체 길이 확정.
            case durationLoaded(TimeInterval)
            /// 끝까지 재생됨 — 컨트롤을 다시 띄운다.
            case playbackFinished
            /// AVPlayer 재생 실패 — View 가 재생 에러 콜백에서 올린다.
            case playbackFailed(message: String)
            /// 자동 숨김 타이머 만료.
            case controlsHideElapsed
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 뒤로 — 코디네이터가 스택을 pop. 리포트 메인까지다(시트는 닫힌 채).
            case backRequested
            /// 왔던 하이라이트 상세 시트로 — pop 하고 그 시트를 다시 올린다 (사용자 결정 2026-08-06).
            case returnToHighlightSheetRequested
        }
    }

    private enum CancelID { case controlsHide }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)

            case let .inner(action):
                return reduceInner(&state, action)

            // «영상 보러가기» 는 이 판에서 안 뜬다(위 `userTappedHighlight` 참조) — 받을 delegate 가 없다.
            // 시트를 손으로 내렸을 때 — 하이라이트를 보려고 멈췄던 재생을 되돌린다.
            // 재생 실패거나 이미 끝까지 본 영상은 되돌릴 재생이 없다.
            case .highlightDetail(.dismiss):
                guard state.playbackFailureMessage == nil, !state.hasReachedEnd else { return .none }
                state.isPlaying = true
                return startControlsHideTimer()

            case .highlightDetail:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$highlightDetail, action: \.highlightDetail) {
            ReportHighlightDetailFeature()
        }
    }

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            return startControlsHideTimer()

        case .userTappedBack:
            return .send(.delegate(.backRequested))

        case .userTappedReturnToPrevious:
            return .send(.delegate(.returnToHighlightSheetRequested))

        case .userTappedSurface:
            // 대본이 떠 있는 동안은 화면 탭이 딤·재생 버튼을 만지지 않는다 (대본이 화면 주인).
            guard !state.isTranscriptOverlayVisible else { return .none }
            state.areControlsVisible.toggle()
            return state.areControlsVisible ? startControlsHideTimer() : .cancel(id: CancelID.controlsHide)

        case .userTappedPlayPause:
            // 끝까지 본 뒤 누르면 처음부터 — AVPlayer 는 끝에 멈춘 채로 play() 해도 움직이지 않는다.
            if !state.isPlaying, state.hasReachedEnd {
                return seek(&state, to: 0, resuming: true)
            }
            state.isPlaying.toggle()
            state.areControlsVisible = true
            // 멈춰 둔 채로는 컨트롤을 숨기지 않는다 — 다시 재생할 방법이 사라진다.
            return state.isPlaying ? startControlsHideTimer() : .cancel(id: CancelID.controlsHide)

        case .userTappedPlaybackRetry:
            // 실패 안내를 걷고 플레이어 재생성을 명령한다 — 만료가 아니라 전송·디코딩 실패라
            // 같은 URL 로 다시 걸면 살아날 수 있다(만료면 진입 자체가 없다).
            state.playbackFailureMessage = nil
            state.reloadToken += 1
            state.isPlaying = true
            state.areControlsVisible = true
            return startControlsHideTimer()

        // 화살표는 «턴 = 이동 단위» 규약을 그대로 따른다 — 진행바 칸과 같은 눈금으로 움직여서
        // 어디로 가는지 하단 바가 미리 보여준다(초 단위 건너뛰기면 칸과 어긋난다).
        case .userTappedPreviousChunk:
            guard let start = state.previousChunkStart else { return .none }
            return seek(&state, to: start)

        case .userTappedNextChunk:
            guard let start = state.nextChunkStart else { return .none }
            return seek(&state, to: start)

        case .userTappedTranscriptToggle:
            // 대본이 없으면 버튼도 없다 — 그래도 신호가 오면 무시한다(빈 판을 띄우지 않게).
            guard state.hasTranscript else { return .none }
            state.isTranscriptVisible.toggle()
            state.areControlsVisible = true
            return state.isTranscriptVisible
                ? .cancel(id: CancelID.controlsHide)
                : startControlsHideTimer()

        case let .userTappedChunk(index):
            guard let chunk = state.transcript.chunks.first(where: { $0.id == index }) else { return .none }
            return seek(&state, to: chunk.start)

        case let .userTappedHighlight(cardIndex, spanIndex):
            return presentHighlight(&state, cardIndex: cardIndex, spanIndex: spanIndex)
        }
    }

    /// 대본 하이라이트 → 상세 시트. 카드·구간 인덱스가 어긋나면 아무 일도 하지 않는다.
    private func presentHighlight(
        _ state: inout State,
        cardIndex: Int,
        spanIndex: Int
    ) -> Effect<Action> {
        guard state.cards.indices.contains(cardIndex) else { return .none }
        let card = state.cards[cardIndex]
        guard let spans = card.highlightSpans, spans.indices.contains(spanIndex) else { return .none }
        guard let context = HighlightContext(card: card, span: spans[spanIndex]) else { return .none }
        // 시트를 보는 동안 영상은 멈춘다 (Figma 주석 «바텀시트 올라왔을 때 영상 정지»).
        state.isPlaying = false
        // 여기가 이미 영상이라 «영상 보러가기» 는 갈 곳이 없다 — 플레이어에서 올린 시트는 늘 숨긴다.
        state.highlightDetail = ReportHighlightDetailFeature.State(
            context: context,
            showsVideoJump: false
        )
        return .cancel(id: CancelID.controlsHide)
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .timeUpdated(time):
            // 이동 직후 한두 번은 AVPlayer 가 아직 이전 위치를 보고한다 —
            // 목표에 닿기 전 값을 그대로 쓰면 진행바가 눌렀던 자리에서 되돌아간다.
            if state.isSeeking {
                guard abs(time - state.seekTarget) < Self.seekSettleTolerance else { return .none }
                state.isSeeking = false
            }
            state.currentTime = time
            state.transcriptPosition = state.transcript.position(at: time)
            return .none

        case let .durationLoaded(duration):
            state.duration = duration
            return .none

        case .playbackFinished:
            state.isPlaying = false
            state.areControlsVisible = true
            return .cancel(id: CancelID.controlsHide)

        case let .playbackFailed(message):
            state.playbackFailureMessage = message
            state.isPlaying = false
            return .cancel(id: CancelID.controlsHide)

        case .controlsHideElapsed:
            state.areControlsVisible = false
            return .none
        }
    }

    /// 이동 명령. 목표 시각을 영상 범위로 자르고 토큰을 올려 뷰가 seek 하게 한다.
    private func seek(
        _ state: inout State,
        to time: TimeInterval,
        resuming: Bool = false
    ) -> Effect<Action> {
        // duration 을 아직 모르면(0) 상한을 걸지 않는다 — 0 으로 잘라 앞으로 못 가는 걸 막는다.
        let upperBound = state.duration > 0 ? state.duration : .greatestFiniteMagnitude
        let target = min(max(0, time), upperBound)
        state.seekTarget = target
        state.seekToken += 1
        state.currentTime = target
        state.transcriptPosition = state.transcript.position(at: target)
        state.isSeeking = true
        state.areControlsVisible = true
        if resuming { state.isPlaying = true }
        return state.isPlaying ? startControlsHideTimer() : .cancel(id: CancelID.controlsHide)
    }

    private func startControlsHideTimer() -> Effect<Action> {
        .run { send in
            try await clock.sleep(for: Self.controlsHideDelay)
            await send(.inner(.controlsHideElapsed))
        }
        .cancellable(id: CancelID.controlsHide, cancelInFlight: true)
    }
}
