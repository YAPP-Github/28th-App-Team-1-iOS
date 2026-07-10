import ComposableArchitecture
import Feature

// @lat: [[app]]
// depends-on: [[auth]] — 로그인 전/후 루트 게이트. cross-feature 조립은 AppFeature 에서만.
// depends-on: [[home]] — Home 을 탭으로 임베드(owner). cross-feature delegate 라우팅은 Feature 추가 시 이 자리에서 조립.
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
    }

    enum Action: BindableAction {
        case onAppear
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
        case binding(BindingAction<State>)
    }

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
                return .none
            case .auth(.delegate(.signedIn)):
                state.isAuthenticated = true
                return .none
            case .auth:
                return .none
            case .home:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
