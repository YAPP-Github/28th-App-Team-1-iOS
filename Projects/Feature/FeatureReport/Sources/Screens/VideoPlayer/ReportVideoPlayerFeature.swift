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
/// 진행바 칸 채움, 대본 오버레이의 «현재 줄» 이 모두 시각에 딸린 화면 상태라서 State 없이 못 만든다.
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
        /// 세션 전체 발화 타임라인 — 진행바 칸의 재료(면접관 멘트 포함).
        public let script: [ScriptSegment]
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
        /// 지금 재생 중인 대본 줄(카드 인덱스). 시각에서 파생되지만 **State 에 둔다** —
        /// 매 0.2초 시각 갱신마다 오버레이 전체를 다시 그리지 않게, 줄이 바뀔 때만 값이 변하게.
        public var currentLineID: Int?
        @Presents public var highlightDetail: ReportHighlightDetailFeature.State?

        public init(
            videoURL: URL,
            startAt: TimeInterval? = nil,
            cards: [InterviewReportCard] = [],
            script: [ScriptSegment] = [],
            entry: Entry = .reportMain
        ) {
            self.videoURL = videoURL
            self.startAt = startAt
            self.cards = cards
            self.script = script
            self.entry = entry
            self.transcript = VideoTranscript(cards: cards, script: script)
            self.currentTime = startAt ?? 0
            self.currentLineID = transcript.currentLineID(at: currentTime)
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
            /// 하단 «이전 화면으로 가기» — 시트 진입 판에만 있는 버튼이고, 하는 일은 X 와 같다.
            case userTappedReturnToPrevious
            /// 영상 아무 곳 — 컨트롤 표시 토글.
            case userTappedSurface
            case userTappedPlayPause
            /// 재생 실패 안내의 «다시 시도» — 플레이어를 새로 만들어 보던 시각부터 다시 건다.
            // TODO(prd-외): PRD 에 재생 실패 UX 가 없어 관례(재시도 버튼)로 메운 재량 구현 — 시안 나오면 재검토.
            case userTappedPlaybackRetry
            /// 왼쪽 화살표 — 진행바 한 칸(대본 구간) 되돌리기. 초 단위가 아니다.
            case userTappedPreviousChunk
            /// 오른쪽 화살표 — 진행바 한 칸(대본 구간) 앞으로.
            case userTappedNextChunk
            /// 하단 아이콘 — 대본 오버레이 토글.
            case userTappedTranscriptToggle
            /// 진행바 칸 — 그 구간 시작으로 이동.
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
            /// 뒤로 — 코디네이터가 스택을 pop.
            case backRequested
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

            // 시트의 «영상 보러가기» — 시트를 닫고 그 장면부터 다시 재생한다.
            // 근거 시각을 모르면(서버 timestamp 확장 전) 처음부터 재생한다.
            case let .highlightDetail(.presented(.delegate(.videoJumpRequested(at)))):
                state.highlightDetail = nil
                return seek(&state, to: at ?? 0, resuming: true)

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

        case .userTappedBack, .userTappedReturnToPrevious:
            return .send(.delegate(.backRequested))

        case .userTappedSurface:
            // 대본을 켜 둔 동안은 화면 탭이 딤·재생 버튼을 만지지 않는다 (대본이 화면 주인).
            guard !state.isTranscriptVisible else { return .none }
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

        // 화살표는 «구간 = 이동 단위» 규약을 그대로 따른다 — 진행바 칸과 같은 눈금으로 움직여서
        // 어디로 가는지 하단 바가 미리 보여준다(초 단위 건너뛰기면 칸과 어긋난다).
        case .userTappedPreviousChunk:
            guard let start = state.previousChunkStart else { return .none }
            return seek(&state, to: start)

        case .userTappedNextChunk:
            guard let start = state.nextChunkStart else { return .none }
            return seek(&state, to: start)

        case .userTappedTranscriptToggle:
            state.isTranscriptVisible.toggle()
            state.areControlsVisible = true
            return state.isTranscriptVisible
                ? .cancel(id: CancelID.controlsHide)
                : startControlsHideTimer()

        case let .userTappedChunk(index):
            guard let chunk = state.transcript.chunks.first(where: { $0.id == index }) else { return .none }
            return seek(&state, to: chunk.start)

        case let .userTappedHighlight(cardIndex, spanIndex):
            guard state.cards.indices.contains(cardIndex) else { return .none }
            let card = state.cards[cardIndex]
            guard let spans = card.highlightSpans, spans.indices.contains(spanIndex) else { return .none }
            guard let context = HighlightContext(card: card, span: spans[spanIndex]) else { return .none }
            // 시트를 보는 동안 영상은 멈춘다 (Figma 주석 «바텀시트 올라왔을 때 영상 정지»).
            state.isPlaying = false
            state.highlightDetail = ReportHighlightDetailFeature.State(
                context: context,
                showsVideoJump: true
            )
            return .cancel(id: CancelID.controlsHide)
        }
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
            state.currentLineID = state.transcript.currentLineID(at: time)
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
        state.currentLineID = state.transcript.currentLineID(at: target)
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

// MARK: - 표시 파생값

// 파생값은 모듈 안(View) 에서만 쓰고 `VideoTranscript` 를 노출하므로 internal 로 둔다.
extension ReportVideoPlayerFeature.State {
    /// 진행바 칸. 서버 구간이 없으면 영상 전체를 한 칸으로 대체한다 — 바가 사라지지 않게.
    /// 이 대체 칸은 `transcript.chunks` 에 없어서 탭해도 아무 일이 없다(이동할 구간을 모른다).
    var progressChunks: [VideoTranscript.Chunk] {
        guard transcript.chunks.isEmpty else { return transcript.chunks }
        return [VideoTranscript.Chunk(id: 0, start: 0, end: max(duration, 1))]
    }

    /// 지금 재생 위치가 걸린 진행바 칸. 첫 칸보다 앞이면 첫 칸으로 본다.
    var currentChunkIndex: Int? {
        let chunks = progressChunks
        guard !chunks.isEmpty else { return nil }
        return chunks.lastIndex(where: { $0.start <= currentTime }) ?? 0
    }

    /// 왼쪽 화살표가 갈 시각 — 한 칸 앞 칸의 시작. 첫 칸에서 누르면 그 칸을 다시 처음부터.
    var previousChunkStart: TimeInterval? {
        let chunks = progressChunks
        guard let index = currentChunkIndex else { return nil }
        return chunks[max(0, index - 1)].start
    }

    /// 오른쪽 화살표가 갈 시각 — 다음 칸의 시작. 마지막 칸에선 갈 곳이 없어 nil(탭 무반응).
    var nextChunkStart: TimeInterval? {
        let chunks = progressChunks
        guard let index = currentChunkIndex, chunks.indices.contains(index + 1) else { return nil }
        return chunks[index + 1].start
    }

    /// 오버레이 대본 줄.
    var transcriptLines: [VideoTranscript.Line] { transcript.lines }

    /// 끝까지 재생됐는지. 길이를 모르면(0) 판정하지 않는다.
    var hasReachedEnd: Bool { duration > 0 && currentTime >= duration }

    /// 가운데 재생 컨트롤 노출 조건 — 대본을 켜면 대본이 화면 주인이라 컨트롤은 비운다.
    var isPlaybackControlVisible: Bool {
        areControlsVisible && !isTranscriptVisible && playbackFailureMessage == nil && !isHighlightDetailPresented
    }

    /// 하단 바(진행바 + 대본 버튼 + 시트 진입 판의 «이전 화면으로 가기») 노출 조건 —
    /// **자동 숨김을 타지 않는다**: 진행바·대본 버튼은 화면의 붙박이고 딤·재생 버튼만 3초 뒤 사라진다.
    /// 재생 실패(안내가 화면을 차지)와 상세 시트(아래 사유)에서만 비운다.
    var isBottomBarVisible: Bool {
        playbackFailureMessage == nil && !isHighlightDetailPresented
    }

    /// 하단 스크림 노출 조건 — 붙박이 하단 바가 밝은 영상 위에서도 읽히게 한다(Figma 443:7830).
    /// 대본을 켜면 오버레이가 제 스크림(`.darkOpen`)을 갖고 있어 겹쳐 깔지 않는다.
    var isBottomScrimVisible: Bool { isBottomBarVisible && !isTranscriptVisible }

    /// 하단 «이전 화면으로 가기» 노출 조건 — 시트로 들어온 판에만 있다.
    var isReturnToPreviousVisible: Bool { entry == .highlightSheet }

    /// 상단 X 노출 조건 — 시트를 보는 동안은 비운다.
    var isCloseButtonVisible: Bool { !isHighlightDetailPresented }

    /// 상세 시트가 올라와 있는 동안은 플레이어 컨트롤을 전부 비운다 (사용자 결정 2026-08-06).
    /// 시트는 화면을 다 덮지 않아 위쪽 띠에 X 가 남는데, 그 X 는 시트 밖이라 눌리고
    /// 눌리면 보던 하이라이트째로 플레이어를 떠난다 — 시트를 내리는 게 먼저다.
    private var isHighlightDetailPresented: Bool { highlightDetail != nil }
}
