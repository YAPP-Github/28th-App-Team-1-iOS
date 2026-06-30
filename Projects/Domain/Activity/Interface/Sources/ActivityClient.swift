import ComposableArchitecture
import Foundation

public struct ActivityClient: Sendable {
    public var fetchActivities: @Sendable () async throws -> [ActivityItem]
    public var clearAll: @Sendable () async throws -> Void

    public init(
        fetchActivities: @escaping @Sendable () async throws -> [ActivityItem],
        clearAll: @escaping @Sendable () async throws -> Void
    ) {
        self.fetchActivities = fetchActivities
        self.clearAll = clearAll
    }
}

extension ActivityClient: TestDependencyKey {
    private static let mockItems: [ActivityItem] = [
        .init(id: 1, title: "Ada followed you", subtitle: "방금 전"),
        .init(id: 2, title: "Alan liked your post", subtitle: "5분 전"),
        .init(id: 3, title: "Grace commented on your photo", subtitle: "1시간 전")
    ]

    public static let previewValue = ActivityClient(
        fetchActivities: { mockItems },
        clearAll: {}
    )

    public static let testValue = ActivityClient(
        fetchActivities: unimplemented("ActivityClient.fetchActivities", placeholder: []),
        clearAll: unimplemented("ActivityClient.clearAll")
    )
}

extension DependencyValues {
    public var activityClient: ActivityClient {
        get { self[ActivityClient.self] }
        set { self[ActivityClient.self] = newValue }
    }
}

public enum ActivityClientError: Error, Equatable {
    case unknown
}
