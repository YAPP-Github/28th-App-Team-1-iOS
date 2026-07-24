//
//  AppFeature.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainAuthInterface
import Feature

// @lat: [[app]]
// depends-on: [[auth]] — 로그인 전/후 루트 게이트. cross-feature 조립은 AppFeature 에서만.
// depends-on: [[home]] — Home 을 탭으로 임베드(owner). cross-feature delegate 라우팅은 Feature 추가 시 이 자리에서 조립.
// depends-on: [[onboarding]] — dev 전용 진입(Home 버튼)으로 온보딩 위저드를 present. 조립은 여기서만 (온보딩 본체 통합 전 임시).
@Reducer
struct AppFeature {
    /// 탭 식별자. 새 탭 추가 시: 여기 case → State 프로퍼티 → body Scope → AppView tabItem 순으로 확장.
    enum Tab: Hashable {
        case home
    }

    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        /// 로그인 게이트. 토큰 영속화가 없으므로 앱 재실행 시 항상 false에서 시작(의도된 범위 제한).
        var isAuthenticated = false
        var home = HomeFeature.State()
        var selectedTab: Tab = .home
        /// dev 전용 온보딩 위저드 — Home 진입 버튼으로 present (온보딩 본체 통합 전 임시).
        @Presents var onboarding: OnboardingFeature.State?
    }

    enum Action: BindableAction {
        case onAppear
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        /// 로그아웃 정리(서버·토큰·draft) 완료 — 초기 State 로 리셋해 로그인 화면으로 돌아간다.
        case sessionCleared
        case binding(BindingAction<State>)
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.onboardingDraftStore) var draftStore

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                // dev 계에서만 Home 온보딩 진입·디버그 로그아웃 버튼을 노출한다.
                state.home.showsOnboardingEntry = AppEnvironment.isDev
                state.home.showsDebugLogout = AppEnvironment.isDev
                return .none
            case .auth(.delegate(.signedIn)):
                // 새 로그인 = 새 세션. 이전 사용자가 하던 화면·데이터를 전부 버리고 초기 State 에서 시작한다.
                state = State()
                state.isAuthenticated = true
                state.home.showsOnboardingEntry = AppEnvironment.isDev
                state.home.showsDebugLogout = AppEnvironment.isDev
                return .none
            case .auth:
                return .none
            case .home(.delegate(.onboardingRequested)):
                state.onboarding = OnboardingFeature.State()
                return .none
            case .home(.delegate(.logoutRequested)):
                // 서버 로그아웃(+토큰 Keychain 삭제)·온보딩 draft(UserDefaults) 삭제. 실패해도 로컬 정리는 진행.
                return .run { send in
                    try? await authClient.logout()
                    draftStore.clear()
                    await send(.sessionCleared)
                }
            case .home:
                return .none
            // 온보딩 완료(분석까지)/중도 이탈 모두 위저드를 닫는다. finished(sessionId:) 는
            // 본체 통합 시 Part2 진입에 쓰지만 dev 진입에선 닫기만 한다.
            case .onboarding(.presented(.delegate(.finished))),
                 .onboarding(.presented(.delegate(.dismiss))):
                state.onboarding = nil
                return .none
            case .onboarding:
                return .none
            case .sessionCleared:
                // 로그아웃 정리 완료 — 초기 State 로 리셋(isAuthenticated=false → 첫 소셜 로그인 화면).
                state = State()
                state.home.showsOnboardingEntry = AppEnvironment.isDev
                state.home.showsDebugLogout = AppEnvironment.isDev
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
