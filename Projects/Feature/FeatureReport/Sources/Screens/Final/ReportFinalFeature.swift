//
//  ReportFinalFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture

// @lat: [[report#최종 보고서]]
/// 최종 보고서 — 지인 피드백이 도착한 뒤 보는 «지인 vs AI» 2축 보고서.
/// **Part 4.6 스펙 대기 자리표시** — 데이터는 `InterviewReport.guestFeedback` 으로 이미 내려오지만
/// 진입 판정 조건(무엇을 «도착»으로 볼지)이 미확정이라 코디네이터가 아직 push 하지 않는다.
/// 구조는 표준 3분류(view/inner/delegate — D5) 그대로 유지한다.
@Reducer
public struct ReportFinalFeature {
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
