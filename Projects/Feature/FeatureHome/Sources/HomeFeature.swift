//
//  HomeFeature.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture

// @lat: [[home]]
/// 홈 — 화면 1개를 `phase` 하나로 관리한다(GuestFeedback 패턴 — 선형 플로우가 아니라 서버 상태의 표시라
/// StackState 를 두지 않는다). Figma 프레임 4종(HomeDefault·HomeReport·HomeStartInterview·HomeDuringInterview)이
/// phase 4종과 1:1 이다. phase 는 서버 판정의 표시일 뿐 — 진실은 탭 시점 게이트(checkStartEligibility) 재검증.
@Reducer
public struct HomeFeature {
    /// 화면 상태 — Figma 프레임 4종과 1:1. 의미·하위 변형은 Figma 수령 시 확정(docs/work/home-account.md §3).
    public enum Phase: Equatable, Sendable {
        /// HomeDefault — 기본 상태.
        case `default`
        /// HomeReport — 면접 기록(레포트) 표시 상태.
        case report
        /// HomeStartInterview — 시작 CTA 변형.
        case startInterview(StartVariant)
        /// HomeDuringInterview — 진행 중 면접·레포트 제작 시점.
        case duringInterview(DuringVariant)
    }

    /// HomeStartInterview 하위 변형 — 처음 / 등록 포폴 있음 / 무료 횟수 모두 사용.
    public enum StartVariant: Equatable, Sendable {
        case first
        case hasPortfolio
        case exhausted
    }

    /// HomeDuringInterview 하위 변형 — 진행 중 면접 있음 / 레포트 제작 중.
    public enum DuringVariant: Equatable, Sendable {
        case inProgress
        case reportGenerating
    }

    @ObservableState
    public struct State: Equatable {
        /// 화면 상태 — 홈 진입 시 로드 결과(잔여·기록·진행 중 세션·포폴)가 결정한다.
        public var phase: Phase = .default
        /// dev 진입점 노출 여부 — AppFeature 가 dev 빌드에서만 켠다 (온보딩 본체 통합 전 임시 진입).
        public var showsOnboardingEntry: Bool
        /// dev 디버그 로그아웃 버튼 노출 여부 — AppFeature 가 dev 빌드에서만 켠다.
        public var showsDebugLogout: Bool

        public init(
            phase: Phase = .default,
            showsOnboardingEntry: Bool = false,
            showsDebugLogout: Bool = false
        ) {
            self.phase = phase
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
            // TODO: 홈 진입 4종 로드(잔여·기록 리스트·진행 중 세션·포폴 상태) — 묶음 API 여부 서버 협의(미결 6-1) 후 배선.
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
