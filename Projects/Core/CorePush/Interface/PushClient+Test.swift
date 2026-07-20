//
//  PushClient+Test.swift
//  CorePushInterface
//
//  Created by EunseoKim on 26/07/20.
//

import ComposableArchitecture

extension PushClient {
    public static let testValue = PushClient(
        configure: unimplemented("PushClient.configure"),
        requestAuthorization: unimplemented("PushClient.requestAuthorization"),
        registerAPNSToken: unimplemented("PushClient.registerAPNSToken"),
        fcmTokenUpdates: unimplemented(
            "PushClient.fcmTokenUpdates",
            placeholder: AsyncStream { $0.finish() }
        ),
        events: unimplemented(
            "PushClient.events",
            placeholder: AsyncStream { $0.finish() }
        )
    )

    public static let previewValue = PushClient(
        configure: {},
        requestAuthorization: { true },
        registerAPNSToken: { _ in },
        fcmTokenUpdates: { AsyncStream { $0.finish() } },
        events: { AsyncStream { $0.finish() } }
    )
}
