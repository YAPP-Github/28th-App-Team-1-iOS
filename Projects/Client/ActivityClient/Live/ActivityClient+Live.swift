//
//  ActivityClient+Live.swift
//  ActivityClientLive
//

import ActivityClientInterface
import ComposableArchitecture
import Foundation
import Models

/// 실제 실행 환경에서 사용하는 ``ActivityClient`` 구현.
///
/// App 타겟이 link 하기만 하면 `liveValue` 가 자동 활성화된다.
extension ActivityClient: DependencyKey {
    public static let liveValue = ActivityClient(
        fetchActivities: {
            try await Task.sleep(for: .milliseconds(600))
            return ActivityItem.samples
        },
        clearAll: {
            try await Task.sleep(for: .milliseconds(300))
        }
    )
}
