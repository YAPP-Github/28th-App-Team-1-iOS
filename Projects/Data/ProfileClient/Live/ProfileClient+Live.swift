//
//  ProfileClient+Live.swift
//  ProfileClientLive
//

import ComposableArchitecture
import Foundation
import Models
import ProfileClientInterface

extension ProfileClient: DependencyKey {
    public static let liveValue = ProfileClient(
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
}
