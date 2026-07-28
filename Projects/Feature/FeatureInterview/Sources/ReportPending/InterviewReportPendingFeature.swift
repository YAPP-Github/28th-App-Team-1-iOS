//
//  InterviewReportPendingFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/27.
//

import ComposableArchitecture

// @lat: [[interview#리포트 대기]]
/// 면접 종료 후 리포트 대기 화면 (Interview_ReportPending, PRD §3.8) — «리포트를 만들고 있어요» + 홈으로.
/// 리포트 완료 폴링·재진입 상태 표시는 Part 3/홈 몫 — 이 화면은 안내와 이탈 신호만 담당한다.
/// 금지 문구(§3.8): «나가도 돼요» · «앱을 닫아도 돼요» · «완료되면 알려드려요»(푸시 없음 — 못 지킬 약속).
@Reducer
public struct InterviewReportPendingFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case userTappedGoHome
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {}

        /// 부모(코디네이터) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 홈으로 — 면접 흐름 종료(정상). dismiss 는 AppFeature 몫.
            case goHomeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.userTappedGoHome):
                return .send(.delegate(.goHomeRequested))
            case .inner, .delegate:
                return .none
            }
        }
    }
}
