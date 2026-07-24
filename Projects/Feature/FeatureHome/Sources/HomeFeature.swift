//
//  HomeFeature.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture

// @lat: [[home]]
@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        /// dev 진입점 노출 여부 — AppFeature 가 dev 빌드에서만 켠다 (온보딩 본체 통합 전 임시 진입).
        public var showsOnboardingEntry: Bool
        /// dev 디버그 로그아웃 버튼 노출 여부 — AppFeature 가 dev 빌드에서만 켠다.
        public var showsDebugLogout: Bool

        public init(showsOnboardingEntry: Bool = false, showsDebugLogout: Bool = false) {
            self.showsOnboardingEntry = showsOnboardingEntry
            self.showsDebugLogout = showsDebugLogout
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            case onAppear
            /// dev 진입 버튼 탭 — 온보딩 시작 요청.
            case userTappedOnboarding
            /// dev 디버그 로그아웃 탭 — 세션·토큰·draft 전체 삭제 요청.
            case userTappedLogout
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {}

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {
            /// dev 온보딩 진입 요청 — 조립은 AppFeature 가 한다 (Feature→Feature 금지).
            case onboardingRequested
            /// dev 디버그 로그아웃 요청 — orchestration(logout API·draft clear·State 리셋)은 AppFeature.
            case logoutRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .view(.userTappedOnboarding):
                return .send(.delegate(.onboardingRequested))
            case .view(.userTappedLogout):
                return .send(.delegate(.logoutRequested))
            case .inner, .delegate:
                return .none
            }
        }
    }
}
