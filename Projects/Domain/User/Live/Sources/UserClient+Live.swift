import AppConfig
import ComposableArchitecture
import Foundation
import DomainUserInterface

extension UserClient: @retroactive DependencyKey {
    public static var liveValue: UserClient {
        @Dependency(\.appConfig) var config

        return UserClient(
            fetchUsers: {
                try await Task.sleep(for: .milliseconds(800))
                return [
                    User(id: 1, name: "Ada Lovelace", email: "ada@example.com"),
                    User(id: 2, name: "Alan Turing", email: "alan@example.com"),
                    User(id: 3, name: "Grace Hopper", email: "grace@example.com"),
                    User(id: 4, name: "Linus Torvalds", email: "linus@example.com")
                ]
            },
            fetchUser: { id in
                try await Task.sleep(for: .milliseconds(500))
                let users: [User] = [
                    User(id: 1, name: "Ada Lovelace", email: "ada@example.com"),
                    User(id: 2, name: "Alan Turing", email: "alan@example.com"),
                    User(id: 3, name: "Grace Hopper", email: "grace@example.com"),
                    User(id: 4, name: "Linus Torvalds", email: "linus@example.com")
                ]
                guard let user = users.first(where: { $0.id == id }) else {
                    throw UserClientError.notFound
                }
                return User(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    bio: "[\(config.environment.rawValue)] \(config.baseURL.host() ?? "") · \(user.name)"
                )
            }
        )
    }
}
