import ComposableArchitecture

// @lat: [[home]]
@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            case onAppear
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {}

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {}
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .inner, .delegate:
                return .none
            }
        }
    }
}
