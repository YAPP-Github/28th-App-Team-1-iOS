import ComposableArchitecture
import Foundation

/// 프로필 조회/저장 통로.
///
/// 패턴은 ``UserClient`` 와 동일합니다. ``ProfileFeature`` 에서
/// `@Dependency(\.profileClient)` 로 주입받아 사용하며, 테스트에서는
/// `withDependencies` 로 mock 을 갈아끼웁니다.
struct ProfileClient: Sendable {
    var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    var saveProfile: @Sendable (_ profile: Profile) async throws -> Profile
}

extension ProfileClient: DependencyKey {
    static let liveValue = ProfileClient(
        fetchProfile: { id in
            try await Task.sleep(for: .milliseconds(600))
            guard let user = User.samples.first(where: { $0.id == id }) else {
                throw ProfileClientError.notFound
            }
            return Profile(
                id: id,
                displayName: user.name,
                bio: "Bio fetched from server for \(user.name).",
                location: "Seoul"
            )
        },
        saveProfile: { profile in
            try await Task.sleep(for: .milliseconds(400))
            return profile
        }
    )

    static let previewValue = ProfileClient(
        fetchProfile: { id in
            Profile(
                id: id,
                displayName: "Preview Name",
                bio: "Preview bio for id \(id).",
                location: "Preview Land"
            )
        },
        saveProfile: { $0 }
    )

    static let testValue = ProfileClient(
        fetchProfile: unimplemented(
            "ProfileClient.fetchProfile",
            placeholder: Profile(id: 0, displayName: "", bio: "")
        ),
        saveProfile: unimplemented(
            "ProfileClient.saveProfile",
            placeholder: Profile(id: 0, displayName: "", bio: "")
        )
    )
}

extension DependencyValues {
    var profileClient: ProfileClient {
        get { self[ProfileClient.self] }
        set { self[ProfileClient.self] = newValue }
    }
}

enum ProfileClientError: Error, Equatable {
    case notFound
}
