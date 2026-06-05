//
//  ActivityClient.swift
//  ActivityClientInterface
//

import ComposableArchitecture
import Foundation
import Models

/// 활동/알림 데이터의 외부 접근 통로 (Repository).
///
/// Interface target — Feature 는 이 모듈만 import 한다.
/// 실제 구현(`liveValue`)은 ``ActivityClientLive`` 에 분리.
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
    public static let previewValue = ActivityClient(
        fetchActivities: { ActivityItem.samples },
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
