} destination: { store in
    switch store.case {
    case let .detail(detailStore):
        UserDetailView(store: detailStore)
    case let .profile(profileStore):
        ProfileView(store: profileStore)
    }
}
