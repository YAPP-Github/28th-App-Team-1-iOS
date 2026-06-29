import ComposableArchitecture
import Foundation

public struct UserClient: Sendable {
    public var fetchUsers: @Sendable () async throws -> [User]
    public var fetchUser: @Sendable (Int) async throws -> User

    public init(
        fetchUsers: @escaping @Sendable () async throws -> [User],
        fetchUser: @escaping @Sendable (Int) async throws -> User
    ) {
        self.fetchUsers = fetchUsers
        self.fetchUser = fetchUser
    }
}

extension UserClient: TestDependencyKey {
    private static let mockUsers: [User] = [
        .init(id: 1, name: "Ada Lovelace", email: "ada@example.com"),
        .init(id: 2, name: "Alan Turing", email: "alan@example.com"),
        .init(id: 3, name: "Grace Hopper", email: "grace@example.com"),
        .init(id: 4, name: "Linus Torvalds", email: "linus@example.com")
    ]

    public static let previewValue = UserClient(
        fetchUsers: { mockUsers },
        fetchUser: { id in
            guard let user = mockUsers.first(where: { $0.id == id }) else {
                throw UserClientError.notFound
            }
            return User(id: user.id, name: user.name, email: user.email, bio: "Preview bio for \(user.name).")
        }
    )

    public static let testValue = UserClient(
        fetchUsers: unimplemented("UserClient.fetchUsers", placeholder: []),
        fetchUser: unimplemented("UserClient.fetchUser", placeholder: User(id: 0, name: "", email: ""))
    )
}

extension DependencyValues {
    public var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

public enum UserClientError: Error, Equatable {
    case notFound
}
