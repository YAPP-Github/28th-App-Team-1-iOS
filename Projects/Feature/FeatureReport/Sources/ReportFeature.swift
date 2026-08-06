//
//  ReportFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import Foundation

// @lat: [[report#코디네이터]]
/// AI 면접 리포트 코디네이터. 1차 리포트를 루트로 두고 나머지 화면을 `path`(StackState)로 push 한다.
/// 각 화면의 delegate 만 매칭한다 — 화면 간 직접 의존 없음, 조립은 여기서만 (D5).
///
/// **메인이 허브다.** 화면들은 한 줄로 이어지지 않는다 — 영상 플레이어는 리포트의 종속 화면이지
/// 지인 피드백의 앞 단계가 아니고, 영상을 보지 않고 바로 지인에게 보낼 수 있어야 한다.
/// 그래서 각 화면 진입은 메인의 개별 delegate 가 트리거한다 (정의서 §1-1).
///
/// **지인 피드백 도착 후에도 화면이 늘지 않는다** — 결과는 메인의 «지인 피드백» 섹션이 이름 탭 +
/// 태도 평가 목록으로 자라서 보여준다(시안 443:7102). 별도 «최종 보고서» 화면은 없다.
@Reducer
public struct ReportFeature {
    @Reducer
    public enum Path {
        /// 영상 다시보기 — 메인 CTA 또는 상세 시트의 «이 장면 영상으로 보기»
        case videoPlayer(ReportVideoPlayerFeature)
        /// 지인 피드백 요청 — 메인 CTA. 태도 항목 지정 + 공유 링크 생성.
        case peerFeedback(ReportPeerFeedbackFeature)
    }

    // @Reducer enum 이 생성하는 Path.State 는 Equatable 을 자동 채택하지 않는다 —
    // StackState<Path.State> 를 담는 코디네이터 State 의 Equatable 합성을 위해 명시한다.

    @ObservableState
    public struct State: Equatable {
        /// 루트 화면(1차 리포트).
        public var main: ReportMainFeature.State
        /// 이후 화면 네비게이션 스택.
        public var path = StackState<Path.State>()

        public init(sessionId: Int) {
            self.main = ReportMainFeature.State(sessionId: sessionId)
        }
    }

    public enum Action {
        case main(ReportMainFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        /// 부모(AppFeature) 통보. 모듈 안에서 끝나는 전환은 여기 올리지 않는다.
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 리포트 이탈(X) — dismiss 는 부모가 처리한다.
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.main, action: \.main) {
            ReportMainFeature()
        }

        Reduce { state, action in
            switch action {
            case let .main(.delegate(action)):
                return reduceMainDelegate(&state, action)

            case .main:
                return .none

            case let .path(action):
                return reducePath(&state, action)

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    /// 메인(허브)의 신호 → 화면 push 또는 부모 전파.
    private func reduceMainDelegate(
        _ state: inout State,
        _ action: ReportMainFeature.Action.Delegate
    ) -> Effect<Action> {
        switch action {
        case let .videoRequested(startAt, entry):
            guard let url = state.main.playableVideoURL else { return .none }
            state.path.append(.videoPlayer(ReportVideoPlayerFeature.State(
                videoURL: url,
                startAt: startAt,
                cards: state.main.cards,
                script: state.main.report?.script ?? [],
                entry: entry
            )))
            return .none

        case .peerFeedbackRequested:
            state.path.append(.peerFeedback(ReportPeerFeedbackFeature.State(
                sessionId: state.main.sessionId
            )))
            return .none

        case .closeRequested:
            return .send(.delegate(.closeRequested))
        }
    }

    private func reducePath(_ state: inout State, _ action: StackActionOf<Path>) -> Effect<Action> {
        switch action {
        // 뒤로 — 어느 화면에서든 pop. 두 화면 다 X 가 «뒤로» 라서 이탈 신호는 없다
        // (리포트 이탈은 메인의 X 만 담당한다). 플레이어 X 는 메인까지다 — 접어 둔 시트는 버린다.
        case .element(id: _, action: .videoPlayer(.delegate(.backRequested))):
            _ = state.path.popLast()
            state.main.stashedHighlightDetail = nil
            return .none

        case .element(id: _, action: .peerFeedback(.delegate(.backRequested))):
            _ = state.path.popLast()
            return .none

        // 플레이어 하단 «이전 화면으로 가기» — pop 하고 왔던 상세 시트를 다시 올린다.
        // 시트에서 온 판에만 있는 버튼이라 접어 둔 시트가 있다(없으면 메인까지만).
        case .element(id: _, action: .videoPlayer(.delegate(.returnToHighlightSheetRequested))):
            _ = state.path.popLast()
            state.main.highlightDetail = state.main.stashedHighlightDetail
            state.main.stashedHighlightDetail = nil
            return .none

        default:
            return .none
        }
    }
}

extension ReportFeature.Path.State: Equatable {}
