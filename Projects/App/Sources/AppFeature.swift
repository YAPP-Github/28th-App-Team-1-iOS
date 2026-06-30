import ComposableArchitecture

// @lat: [[app#AppFeature Coordinator]]
// depends-on: Feature 서브모듈들의 delegate action을 수신해 cross-feature 라우팅을 담당한다.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        init() {}
    }

    enum Action {
        case onAppear
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
