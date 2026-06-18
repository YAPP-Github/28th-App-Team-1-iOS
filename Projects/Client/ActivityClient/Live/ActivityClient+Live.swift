//
//  ActivityClient+Live.swift
//  ActivityClientLive
//

import ActivityClientInterface
import AppConfig
import ComposableArchitecture
import Foundation
import Models

/// 실제 실행 환경에서 사용하는 ``ActivityClient`` 구현.
///
/// App 타겟이 link 하기만 하면 `liveValue` 가 자동 활성화된다.
/// 환경(개발계/운영계)은 `@Dependency(\.appConfig)` 로 주입받아 `baseURL` 을 고른다.
extension ActivityClient: DependencyKey {
    public static var liveValue: ActivityClient {
        @Dependency(\.appConfig) var config

        return ActivityClient(
            fetchActivities: {
                // 실제 구현: GET config.baseURL.appendingPathComponent("activities")
                _ = config.baseURL
                try await Task.sleep(for: .milliseconds(600))
                return ActivityItem.samples
            },
            clearAll: {
                // 실제 구현: DELETE config.baseURL.appendingPathComponent("activities")
                try await Task.sleep(for: .milliseconds(300))
            }
        )
    }
}
