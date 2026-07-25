//
//  ReportPeerFeedbackFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture

// @lat: [[report#지인 피드백]]
/// 지인 피드백 요청 — 리포트 메인의 «지인에게 면접 영상 보내기» 로 진입한다.
/// **Part 4.5 스펙 대기 자리표시** — 화면 자리와 진입 경로만 확정돼 있고 내용은 비어 있다.
/// 채울 때 지킬 것: 지인에게 넘기는 payload 는 영상과 질문 경계까지다. AI 피드백(하이라이트·진단·
/// 다음 대비)을 넘기면 4.6 의 «지인 vs AI» 2축 비교가 오염된다. 링크 생성은 `FeedbackShareClient`.
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
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
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
            case .delegate:
                return .none
            }
        }
    }
}
