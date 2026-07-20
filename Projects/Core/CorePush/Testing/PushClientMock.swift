//
//  PushClientMock.swift
//  CorePushTesting
//
//  Created by EunseoKim on 26/07/20.
//

import CorePushInterface
import Foundation

public extension PushClient {
    /// 고정 토큰·이벤트 시퀀스를 흘려주는 mock — 다른 모듈의 테스트·Preview 에서 주입한다.
    static func mock(
        authorizationGranted: Bool = true,
        tokens: [String] = ["mock-fcm-token"],
        events: [PushEvent] = []
    ) -> PushClient {
        PushClient(
            configure: {},
            requestAuthorization: { authorizationGranted },
            registerAPNSToken: { _ in },
            fcmTokenUpdates: {
                AsyncStream { continuation in
                    tokens.forEach { continuation.yield($0) }
                    continuation.finish()
                }
            },
            events: {
                AsyncStream { continuation in
                    events.forEach { continuation.yield($0) }
                    continuation.finish()
                }
            }
        )
    }
}
