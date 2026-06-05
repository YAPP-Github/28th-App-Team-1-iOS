import ComposableArchitecture

struct ProfileClient: Sendable {
    var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    var saveProfile:  @Sendable (_ profile: Profile) async throws -> Profile
}

// Interface 모듈에는 test/preview 값만. liveValue 는 Live 모듈의 DependencyKey 로 둔다.
extension ProfileClient: TestDependencyKey {
    static let previewValue = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    static let testValue = ProfileClient(
        fetchProfile: unimplemented("ProfileClient.fetchProfile", placeholder: .stub),
        saveProfile:  unimplemented("ProfileClient.saveProfile",  placeholder: .stub)
    )
}
