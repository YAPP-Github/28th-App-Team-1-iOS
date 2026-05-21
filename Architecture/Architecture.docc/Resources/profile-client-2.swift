import ComposableArchitecture

struct ProfileClient: Sendable {
    var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    var saveProfile:  @Sendable (_ profile: Profile) async throws -> Profile
}

extension ProfileClient: DependencyKey {
    static let liveValue    = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    static let previewValue = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    static let testValue    = ProfileClient(
        fetchProfile: unimplemented("ProfileClient.fetchProfile", placeholder: .stub),
        saveProfile:  unimplemented("ProfileClient.saveProfile",  placeholder: .stub)
    )
}
