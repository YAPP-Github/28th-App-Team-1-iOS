//
//  UserClient.swift
//  UserClient
//
//  Created by EunseoKim on 5/26/26.
//

import ComposableArchitecture
import Foundation
import Models

/// 사용자 데이터의 외부 접근 통로 (Repository).
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

extension UserClient: DependencyKey {
    public static let liveValue = UserClient(
        fetchUsers: {
            try await Task.sleep(for: .milliseconds(800))
            return User.samples
        },
        fetchUser: { id in
            try await Task.sleep(for: .milliseconds(500))
            guard let user = User.samples.first(where: { $0.id == id }) else {
                throw UserClientError.notFound
            }
            return User(id: user.id, name: user.name, email: user.email, bio: "Loaded bio for \(user.name).")
        }
    )

    public static let previewValue = UserClient(
        fetchUsers: { User.samples },
        fetchUser: { id in
            guard let user = User.samples.first(where: { $0.id == id }) else {
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
