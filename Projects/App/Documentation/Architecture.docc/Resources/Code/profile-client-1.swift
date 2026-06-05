import ComposableArchitecture

struct ProfileClient: Sendable {
    var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    var saveProfile:  @Sendable (_ profile: Profile) async throws -> Profile
}
