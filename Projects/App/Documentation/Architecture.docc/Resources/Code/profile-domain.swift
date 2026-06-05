import Foundation

struct Profile: Equatable, Identifiable, Codable, Sendable {
    let id: Int
    var displayName: String
    var bio: String
    var location: String?
}
