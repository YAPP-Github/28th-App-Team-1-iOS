//
//  ReportPeerFeedbackFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture

// @lat: [[report#피드백]]
/// 리포트 피드백 (3/4) — 레이아웃 미정 자리표시. Figma 연결 시 실제 State·UI 로 채운다.
/// 구조는 표준 3분류(view/inner/delegate — D5) 그대로 유지한다.
@Reducer
public struct ReportPeerFeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedBack
            case userTappedClose
            case userTappedContinue
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 다음 화면 요청 — 코디네이터가 push.
            case continueRequested
            /// 뒤로 — 코디네이터가 스택을 pop.
            case backRequested
            /// 리포트 이탈(X).
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .view(.userTappedBack):
                return .send(.delegate(.backRequested))
            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))
            case .view(.userTappedContinue):
                return .send(.delegate(.continueRequested))
            case .delegate:
                return .none
            }
        }
    }
}
