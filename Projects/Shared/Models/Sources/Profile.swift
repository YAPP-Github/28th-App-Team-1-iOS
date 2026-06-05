//
//  Profile.swift
//  Models
//
//  Created by EunseoKim on 5/26/26.
//

import Foundation

/// 사용자 프로필 — `User` 의 편집 가능한 표현.
public struct Profile: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public var displayName: String
    public var bio: String
    public var location: String?

    public init(id: Int, displayName: String, bio: String, location: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.location = location
    }
}
