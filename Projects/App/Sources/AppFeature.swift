import ComposableArchitecture
import Feature

// @lat: [[app]]
// depends-on: [[home]] — Home 을 탭으로 임베드(owner). cross-feature delegate 라우팅은 Feature 추가 시 이 자리에서 조립.
@Reducer
struct AppFeature {
    /// 탭 식별자. 새 탭 추가 시: 여기 case → State 프로퍼티 → body Scope → AppView tabItem 순으로 확장.
    enum Tab: Hashable {
        case home
    }

    @ObservableState
    struct State: Equatable {
        var home = HomeFeature.State()
        var selectedTab: Tab = .home
        init() {}
    }

    enum Action: BindableAction {
        case onAppear
        case home(HomeFeature.Action)
        case binding(BindingAction<State>)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .home:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
