enum Action: BindableAction {
    case binding(BindingAction<State>)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
        case profileSaved(Profile)
    }
}

case let .profileSaved(profile):
    state.isSaving = false
    state.profile = profile
    return .send(.delegate(.profileSaved(profile)))
