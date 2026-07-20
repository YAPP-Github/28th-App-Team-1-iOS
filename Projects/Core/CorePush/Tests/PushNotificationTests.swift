//
//  PushNotificationTests.swift
//  CorePushTests
//
//  Created by EunseoKim on 26/07/20.
//

import CorePushInterface
import XCTest

final class PushNotificationTests: XCTestCase {
    func test_sanitizedData_removesApsSubtree() {
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["title": "제목", "body": "본문"]],
            "screen": "interview"
        ]

        XCTAssertEqual(
            PushNotification.sanitizedData(from: userInfo),
            ["screen": "interview"]
        )
    }

    func test_sanitizedData_keepsOnlyStringKeysAndValues() {
        let userInfo: [AnyHashable: Any] = [
            "id": "42",
            "badgeCount": 3,
            7: "seven"
        ]

        XCTAssertEqual(
            PushNotification.sanitizedData(from: userInfo),
            ["id": "42"]
        )
    }

    func test_sanitizedData_emptyUserInfo_returnsEmpty() {
        XCTAssertEqual(PushNotification.sanitizedData(from: [:]), [:])
    }
}
