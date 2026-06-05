import ComposableArchitecture

@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        let profileId: Int
        var profile: Profile?
        var editedDisplayName = ""
        var editedBio = ""
        var isLoading = false
        var isSaving = false
        var errorMessage: String?

        init(profileId: Int) { self.profileId = profileId }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    @Dependency(\.profileClient) var profileClient

    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}
