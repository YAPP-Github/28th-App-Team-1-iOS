//
//  ProfileClient+Live.swift
//  ProfileClientLive
//

import AppConfig
import ComposableArchitecture
import Foundation
import Models
import ProfileClientInterface

extension ProfileClient: DependencyKey {
    public static var liveValue: ProfileClient {
        @Dependency(\.appConfig) var config

        return ProfileClient(
            fetchProfile: { id in
                // 실제 구현: GET config.baseURL.appendingPathComponent("profiles/\(id)")
                try await Task.sleep(for: .milliseconds(600))
                guard let user = User.samples.first(where: { $0.id == id }) else {
                    throw ProfileClientError.notFound
                }
                return Profile(
                    id: id,
                    displayName: user.name,
                    bio: "[\(config.environment.rawValue)] \(config.baseURL.host() ?? "") · \(user.name)",
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
