case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    state.path.append(.profile(ProfileFeature.State(profileId: id)))
    return .none
