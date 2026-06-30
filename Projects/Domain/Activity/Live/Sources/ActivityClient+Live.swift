import DomainActivityInterface
import ComposableArchitecture
import Foundation

extension ActivityClient: DependencyKey {
    public static var liveValue: ActivityClient {
        ActivityClient(
            fetchActivities: {
                try await Task.sleep(for: .milliseconds(700))
                return [
                    ActivityItem(id: 1, title: "Ada followed you", subtitle: "방금 전"),
                    ActivityItem(id: 2, title: "Alan liked your post", subtitle: "5분 전"),
                    ActivityItem(id: 3, title: "Grace commented on your photo", subtitle: "1시간 전")
                ]
            },
            clearAll: {
                try await Task.sleep(for: .milliseconds(300))
            }
        )
    }
}
