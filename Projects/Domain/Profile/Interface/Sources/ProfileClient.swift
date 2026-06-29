import ComposableArchitecture
import Foundation

public struct ProfileClient: Sendable {
    public var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    public var saveProfile: @Sendable (_ profile: Profile) async throws -> Profile

    public init(
        fetchProfile: @escaping @Sendable (_ id: Int) async throws -> Profile,
        saveProfile: @escaping @Sendable (_ profile: Profile) async throws -> Profile
    ) {
        self.fetchProfile = fetchProfile
        self.saveProfile = saveProfile
    }
}

extension ProfileClient: TestDependencyKey {
    public static let previewValue = ProfileClient(
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

    public static let testValue = ProfileClient(
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
    public var profileClient: ProfileClient {
        get { self[ProfileClient.self] }
        set { self[ProfileClient.self] = newValue }
    }
}

public enum ProfileClientError: Error, Equatable {
    case notFound
}
