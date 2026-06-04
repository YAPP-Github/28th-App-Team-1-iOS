@ObservableState
struct State: Equatable {
    var user: User
    var isLoading = false
    var errorMessage: String?
}

enum Action {
    case userTappedRow(User)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
        case userTappedRow(User)
    }
}
