//
//  PushClient+Live.swift
//  CorePushImplementation
//
//  Created by EunseoKim on 26/07/20.
//

import ComposableArchitecture
import CorePushInterface
import Foundation

extension PushClient: @retroactive DependencyKey {
    /// PushCenter(FCM/APNs 브릿지)로 위임하는 실제 구현. Implementation 은 App/Example 만 link 한다 (D4).
    public static var liveValue: PushClient {
        let center = PushCenter.shared
        return PushClient(
            configure: { center.configure() },
            requestAuthorization: { try await center.requestAuthorization() },
            registerAPNSToken: { center.registerAPNSToken($0) },
            fcmTokenUpdates: { center.tokenStream },
            events: { center.eventStream }
        )
    }
}
