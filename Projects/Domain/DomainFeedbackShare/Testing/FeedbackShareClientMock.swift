//
//  FeedbackShareClientMock.swift
//  DomainFeedbackShareTesting
//
//  Created by EunseoKim on 26/07/23.
//

import DomainFeedbackShareInterface
import Foundation

public extension FeedbackShareClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 활성 링크와 무해한 성공을 돌려준다.
    static var mock: FeedbackShareClient {
        FeedbackShareClient(
            status: { _ in
                FeedbackShareStatus(
                    token: "mock-token",
                    status: .active,
                    axes: ["GAZE", "VOICE"],
                    submittedCount: 1,
                    videoExpiresAt: Date(timeIntervalSince1970: 1_782_172_800),
                    requestedAt: Date(timeIntervalSince1970: 1_782_000_000)
                )
            },
            create: { _, _ in FeedbackShareCreated(token: "mock-token") },
            makePrivate: { _ in }
        )
    }
}
