private enum CancelID { case load, save }

case .onAppear:
    state.isLoading = true
    return .run { [id = state.profileId] send in
        do {
            let profile = try await profileClient.fetchProfile(id)
            await send(.profileLoaded(profile))
        } catch {
            await send(.profileLoadingFailed(error.localizedDescription))
        }
    }
    .cancellable(id: CancelID.load)
