case .onAppear:
    state.isLoading = true
    return .run { [id = state.profileId] send in
        let profile = try await profileClient.fetchProfile(id)
        await send(.profileLoaded(profile))
    }
    .cancellable(id: CancelID.load)
