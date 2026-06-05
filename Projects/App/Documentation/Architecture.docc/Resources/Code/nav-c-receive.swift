case let .path(.element(id: _, action: .profile(.delegate(.profileSaved(profile))))):
    if let i = state.list.users.firstIndex(where: { $0.id == profile.id }) {
        state.list.users[i].name = profile.displayName
        state.list.users[i].bio = profile.bio
    }
    for id in state.path.ids {
        guard case .detail(var detail) = state.path[id: id],
              detail.user.id == profile.id else { continue }
        detail.user.name = profile.displayName
        detail.user.bio = profile.bio
        state.path[id: id] = .detail(detail)
    }
    state.path.removeLast()
    return .none
