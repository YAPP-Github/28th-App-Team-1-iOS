import Foundation

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
