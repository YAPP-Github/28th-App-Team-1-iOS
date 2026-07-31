//
//  HomeFeature.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture

// @lat: [[home]]
/// 홈 — 홈 화면 자체를 `phase` 하나로 관리한다(GuestFeedback 패턴 — 선형 플로우가 아니라 서버 상태의 표시라
/// StackState 를 두지 않는다). phase 는 Figma 프레임 `HomeDefault`·`HomeReport` 와 1:1 이고, 면접 시작은
/// 홈의 상태가 아니라 위로 올라오는 화면이라 `StartInterviewFeature` 를 present 한다.
/// phase 는 서버 판정의 표시일 뿐 — 진실은 탭 시점 게이트(checkStartEligibility) 재검증.
@Reducer
public struct HomeFeature {
    /// 홈 화면 상태 — Figma 프레임 `HomeDefault`·`HomeReport` 와 1:1(docs/work/home-account.md §3).
    public enum Phase: Equatable, Sendable {
        /// HomeDefault — 기본 상태(리포트 없음).
        case `default`
        /// HomeReport — 면접 기록(레포트) 표시 상태.
        case report(ReportVariant)
    }

    /// HomeReport 하위 변형 — 축은 «오랜만이에요 OO님!» 인사말을 띄우는지 하나다.
    /// 리포트 목록·바텀시트는 두 변형이 같다.
    public enum ReportVariant: Equatable, Sendable {
        /// 오랜만에 돌아온 사용자 — 인사말을 띄운다.
        case returning
        /// 최근에 다녀간 사용자 — 인사말을 숨기고 스크롤 안내만 남긴다.
        case recent
    }

    @ObservableState
    public struct State: Equatable {
        /// 화면 상태 — 홈 진입 시 로드 결과(잔여·기록·포폴)가 결정한다.
        public var phase: Phase = .default
        /// present 된 면접 시작 화면 — 홈 탭에 NavigationStack 이 없어 push 가 아니라 cover 다.
        @Presents public var startInterview: StartInterviewFeature.State?
        // TODO: 홈 진입 로드(잔여·포폴)가 정해야 하고, 진실은 탭 시점 게이트 `checkStartEligibility` 재검증
        //       (미결 6-1 서버 협의 대기).
        /// 다음에 열 면접 시작 화면의 변형.
        public var nextStartVariant: StartInterviewFeature.Variant = .first
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
        case startInterview(PresentationAction<StartInterviewFeature.Action>)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            // TODO: 홈 진입 4종 로드(잔여·기록 리스트·진행 중 세션·포폴 상태) — 묶음 API 여부 서버 협의(미결 6-1) 후 배선.
            case onAppear
            /// 면접 시작 요청 — 면접 시작 화면을 present 한다.
            case userTappedStartInterview
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
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .view(.userTappedStartInterview):
                state.startInterview = StartInterviewFeature.State(variant: state.nextStartVariant)
                return .none
            case .view(.userTappedOnboarding):
                return .send(.delegate(.onboardingRequested))
            case .view(.userTappedLogout):
                return .send(.delegate(.logoutRequested))

            case .startInterview(.presented(.delegate(.closeRequested))),
                 .startInterview(.presented(.delegate(.backToHomeRequested))):
                state.startInterview = nil
                return .none
            case .startInterview(.presented(.delegate(.startRequested))),
                 .startInterview(.presented(.delegate(.editInfoRequested))):
                // TODO: 면접 플로우·정보 수정은 다른 Feature 라 AppFeature 가 조립한다(Feature→Feature 금지).
                //       AppFeature 배선과 함께 delegate 케이스 신설 — 지금 Delegate 에 케이스를 추가하면
                //       AppFeature 의 switch 가 깨진다(App 레이어는 이번 작업 범위 밖).
                return .none
            case .startInterview:
                return .none

            case .inner, .delegate:
                return .none
            }
        }
        .ifLet(\.$startInterview, action: \.startInterview) {
            StartInterviewFeature()
        }
    }
}
