case let .list(.delegate(.userTappedRow(user))):
    state.path.append(.detail(UserDetailFeature.State(user: user)))
    return .none
