#Preview {
    NavigationStack {
        ProfileView(
            store: Store(initialState: ProfileFeature.State(profileId: 1)) {
                ProfileFeature()
            } withDependencies: {
                $0.profileClient = .previewValue
            }
        )
    }
}
