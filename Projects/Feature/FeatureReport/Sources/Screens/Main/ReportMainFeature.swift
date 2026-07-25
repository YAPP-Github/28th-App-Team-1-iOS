//
//  ReportMainFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import Foundation

// @lat: [[report#1차 리포트]]
/// 1차 리포트 — 리포트 플로우의 루트이자 상세 화면. 요약 화면을 따로 두지 않는다(구버전 이탈 이력).
/// `InterviewReportClient.report` 한 번으로 전 화면 데이터를 받고, 채점이 끝나지 않았으면 폴링한다.
/// 사용자 문구는 대부분 서버 소유 — 클라는 절단·nil 폴백만 한다 (정의서 §6).
@Reducer
public struct ReportMainFeature {
    /// 채점 폴링 주기 — [[api#Interview Report]] 의 3~5초 규약 중앙값.
    static let pollInterval: Duration = .seconds(4)
    /// 폴링 상한. 서버 SLA 는 24시간이지만 화면이 무한 폴링하면 안 된다 — 넘으면 수동 재시도로 넘긴다.
    static let pollLimit = 75
    /// 한 줄 요약 아래 안내 줄 최대 개수 (PRD 2-4).
    static let maxRedFlagNotices = 2

    @ObservableState
    public struct State: Equatable {
        public let sessionId: Int
        public var loadState: LoadState = .loading
        public var report: InterviewReport?
        /// 폴링 횟수 — 상한 판정용.
        public var pollTickCount = 0
        @Presents public var highlightDetail: ReportHighlightDetailFeature.State?

        public enum LoadState: Equatable, Sendable {
            /// 최초 조회 전 또는 채점 진행 중
            case loading
            case loaded
            /// 폴링 상한 초과 — 수동 재시도 유도
            case pollTimedOut
            case failed(InterviewReportError)
        }

        public init(sessionId: Int) {
            self.sessionId = sessionId
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case highlightDetail(PresentationAction<ReportHighlightDetailFeature.Action>)

        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedClose
            case userTappedWatchVideo
            case userTappedHighlight(cardIndex: Int, spanIndex: Int)
            case userTappedPeerFeedback
            case userTappedRetry
        }

        @CasePathable
        public enum Inner: Equatable, Sendable {
            case reportLoaded(InterviewReport)
            case reportFailed(InterviewReportError)
            /// 폴링 주기 경과 — 재조회 시점.
            case pollTicked
        }

        /// 코디네이터 통보. 화면 push 여부는 코디네이터가 판단한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 영상 보기 — nil 이면 처음부터.
            case videoRequested(startAt: TimeInterval?)
            case peerFeedbackRequested
            /// 분석 부족 — 다시 연습하기.
            case retryRequested
            case closeRequested
        }
    }

    private enum CancelID { case poll }

    @Dependency(\.interviewReportClient) var interviewReportClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)

            case let .inner(action):
                return reduceInner(&state, action)

            // 시트가 «이 장면 영상으로 보기» 를 올리면 닫고 영상 요청으로 번역한다.
            case let .highlightDetail(.presented(.delegate(.videoJumpRequested(at)))):
                state.highlightDetail = nil
                return .send(.delegate(.videoRequested(startAt: at)))

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
            // 재진입(뒤로가기 복귀)에는 이미 받아둔 보고서를 그대로 쓴다.
            guard state.report == nil else { return .none }
            return fetch(sessionId: state.sessionId)

        case .userTappedClose:
            return .send(.delegate(.closeRequested))

        case .userTappedWatchVideo:
            return .send(.delegate(.videoRequested(startAt: nil)))

        case let .userTappedHighlight(cardIndex, spanIndex):
            return presentHighlightDetail(&state, cardIndex: cardIndex, spanIndex: spanIndex)

        case .userTappedPeerFeedback:
            return .send(.delegate(.peerFeedbackRequested))

        case .userTappedRetry:
            return .send(.delegate(.retryRequested))
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .reportLoaded(report):
            state.report = report
            switch report.status {
            case .generating:
                return schedulePoll(&state)
            case .ready, .insufficientAnalysis, .failed:
                state.loadState = .loaded
                return .cancel(id: CancelID.poll)
            }

        case let .reportFailed(error):
            // 보고서 미생성(404)은 실패가 아니라 «아직» — 폴링을 이어간다.
            guard error == .reportNotFound else {
                state.loadState = .failed(error)
                return .cancel(id: CancelID.poll)
            }
            return schedulePoll(&state)

        case .pollTicked:
            return fetch(sessionId: state.sessionId)
        }
    }

    /// 채점이 끝나지 않았을 때 다음 조회를 예약한다. 상한을 넘으면 수동 재시도로 넘긴다.
    private func schedulePoll(_ state: inout State) -> Effect<Action> {
        guard state.pollTickCount < Self.pollLimit else {
            state.loadState = .pollTimedOut
            return .cancel(id: CancelID.poll)
        }
        state.pollTickCount += 1
        state.loadState = .loading
        return .run { send in
            try await clock.sleep(for: Self.pollInterval)
            await send(.inner(.pollTicked))
        }
        .cancellable(id: CancelID.poll)
    }

    private func fetch(sessionId: Int) -> Effect<Action> {
        .run { send in
            await send(.inner(.reportLoaded(try await interviewReportClient.report(sessionId))))
        } catch: { error, send in
            // 취소는 실패가 아니다 — 화면 이탈로 effect 가 끊긴 것뿐이라 에러 상태로 만들지 않는다.
            guard !(error is CancellationError) else { return }
            await send(.inner(.reportFailed(error as? InterviewReportError ?? .unexpected)))
        }
        .cancellable(id: CancelID.poll)
    }

    /// 하이라이트 탭 → 상세 시트. 인덱스가 서버 응답과 어긋나면 조용히 무시한다.
    private func presentHighlightDetail(
        _ state: inout State,
        cardIndex: Int,
        spanIndex: Int
    ) -> Effect<Action> {
        let cards = state.cards
        guard cards.indices.contains(cardIndex) else { return .none }
        let card = cards[cardIndex]
        guard let spans = card.highlightSpans, spans.indices.contains(spanIndex) else { return .none }
        guard let context = HighlightContext(card: card, span: spans[spanIndex]) else { return .none }
        state.highlightDetail = ReportHighlightDetailFeature.State(
            context: context,
            showsVideoJump: state.playableVideoURL != nil
        )
        return .none
    }
}

// MARK: - 표시 파생값

public extension ReportMainFeature.State {
    /// 분석 부족 면접 — 한 줄 요약 자리에 안내문을 쓰고 채점된 카드만 노출한다.
    var isInsufficient: Bool { report?.status == .insufficientAnalysis }

    /// 한 줄 요약 아래 안내 줄 — 최대 2줄로 절단한다.
    var visibleRedFlagNotices: [RedFlagNotice] {
        Array((report?.redFlagNotices ?? []).prefix(ReportMainFeature.maxRedFlagNotices))
    }

    var cards: [InterviewReportCard] { report?.cards ?? [] }

    /// 재생 가능한 영상 주소. 만료·nil·형식 오류를 한 곳에서 흡수해
    /// 플레이어가 만료를 알 필요 없게 한다 (정의서 §8).
    var playableVideoURL: URL? {
        guard let video = report?.video, video.expired != true, let raw = video.url else { return nil }
        return URL(string: raw)
    }
}
