enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case onDisappear
    case userTappedSaveButton
    case profileLoaded(Profile)
    case profileSaved(Profile)
    case profileLoadingFailed(String)
    case profileSaveFailed(String)
    case alertDismissed
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
        case profileSaved(Profile)
    }
}
