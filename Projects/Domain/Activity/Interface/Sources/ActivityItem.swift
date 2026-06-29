import Foundation

public struct ActivityItem: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String

    public init(id: Int, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}
