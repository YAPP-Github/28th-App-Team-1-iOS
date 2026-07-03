import ComposableArchitecture

// @lat: [[home]]
@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }

    public enum Action {}

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, _ in
            return .none
        }
    }
}
