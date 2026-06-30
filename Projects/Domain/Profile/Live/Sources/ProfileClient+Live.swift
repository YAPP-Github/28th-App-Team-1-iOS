import AppConfig
import ComposableArchitecture
import Foundation
import DomainProfileInterface

extension ProfileClient: @retroactive DependencyKey {
    public static var liveValue: ProfileClient {
        @Dependency(\.appConfig) var config

        return ProfileClient(
            fetchProfile: { id in
                // 실제 구현: GET config.baseURL.appendingPathComponent("profiles/\(id)")
                try await Task.sleep(for: .milliseconds(600))
                return Profile(
                    id: id,
                    displayName: "User \(id)",
                    bio: "[\(config.environment.rawValue)] \(config.baseURL.host() ?? "")",
                    location: "Seoul"
                )
            },
            saveProfile: { profile in
                // 실제 구현: PUT config.baseURL.appendingPathComponent("profiles/\(profile.id)")
                try await Task.sleep(for: .milliseconds(400))
                return profile
            }
        )
    }
}
