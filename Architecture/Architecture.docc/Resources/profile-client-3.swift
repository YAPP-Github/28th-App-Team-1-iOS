extension DependencyValues {
    var profileClient: ProfileClient {
        get { self[ProfileClient.self] }
        set { self[ProfileClient.self] = newValue }
    }
}
