import Foundation

/// 사용자 도메인 모델.
public struct User: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public var name: String
    public var email: String
    public var bio: String?

    public init(id: Int, name: String, email: String, bio: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.bio = bio
    }
}

extension User {
    /// mock 샘플 데이터. live/preview client 가 공통으로 사용한다.
    public static let samples: [User] = [
        .init(id: 1, name: "Ada Lovelace", email: "ada@example.com"),
        .init(id: 2, name: "Alan Turing", email: "alan@example.com"),
        .init(id: 3, name: "Grace Hopper", email: "grace@example.com"),
        .init(id: 4, name: "Linus Torvalds", email: "linus@example.com")
    ]
}
