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
/// View-local `@State` 가 소유하고, 재생 위치도 리듀서에 올리지 않는다. 리듀서는 대본 토글·시트·재생 실패만 다룬다.
///
/// **만료 판정은 여기 책임이 아니다** — 리포트가 `playableVideoURL` 로 걸러 만료면 진입 자체가 없다.
/// 이 화면은 재생 실패(네트워크·코덱)만 표시한다.
///
/// STT 오버레이·장면 seek 는 서버 timestamp 확장 대기 (정의서 §8 2단계).
@Reducer
public struct ReportVideoPlayerFeature {
    @ObservableState
    public struct State: Equatable {
        public let videoURL: URL
        /// 진입 시 이동할 시각(초). nil 이면 처음부터 — 확장 전에는 항상 nil.
        public let startAt: TimeInterval?
        /// STT 오버레이 재료 (2단계).
        public let cards: [InterviewReportCard]
        /// 대본 오버레이 표시 여부.
        public var isTranscriptVisible = false
        /// 재생 실패 — 표시할 문구를 동봉한다.
        public var playbackFailureMessage: String?
        @Presents public var highlightDetail: ReportHighlightDetailFeature.State?

        public init(videoURL: URL, startAt: TimeInterval? = nil, cards: [InterviewReportCard] = []) {
            self.videoURL = videoURL
            self.startAt = startAt
            self.cards = cards
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case highlightDetail(PresentationAction<ReportHighlightDetailFeature.Action>)

        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedBack
            case userTappedClose
            /// 하단 아이콘 — 대본 오버레이 토글.
            case userTappedTranscriptToggle
            /// 오버레이 대본의 하이라이트 탭 (2단계).
            case userTappedHighlight(cardIndex: Int, spanIndex: Int)
        }

        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// AVPlayer 재생 실패 — View 가 재생 에러 콜백에서 올린다.
            case playbackFailed(message: String)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 뒤로 — 코디네이터가 스택을 pop.
            case backRequested
            /// 리포트 이탈(X).
            case closeRequested
        }
    }

    /// 재생 실패 문구 — 만료가 아니라 전송·디코딩 실패다.
    static let playbackFailureMessage = "영상을 재생할 수 없어요.\n잠시 후 다시 시도해 주세요."

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)

            case let .inner(.playbackFailed(message)):
                state.playbackFailureMessage = message
                return .none

            // 플레이어 안에서 연 시트는 이미 그 장면이라 점프 신호가 오지 않는다 (showsVideoJump == false).
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
            return .none

        case .userTappedBack:
            return .send(.delegate(.backRequested))

        case .userTappedClose:
            return .send(.delegate(.closeRequested))

        case .userTappedTranscriptToggle:
            state.isTranscriptVisible.toggle()
            return .none

        case let .userTappedHighlight(cardIndex, spanIndex):
            guard state.cards.indices.contains(cardIndex) else { return .none }
            let card = state.cards[cardIndex]
            guard let spans = card.highlightSpans, spans.indices.contains(spanIndex) else { return .none }
            guard let context = HighlightContext(card: card, span: spans[spanIndex]) else { return .none }
            // 재생 중이면 View 가 일시정지한다 — 리듀서는 시트만 올린다.
            state.highlightDetail = ReportHighlightDetailFeature.State(
                context: context,
                showsVideoJump: false
            )
            return .none
        }
    }
}
