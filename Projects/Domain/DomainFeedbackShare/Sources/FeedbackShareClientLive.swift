//
//  FeedbackShareClientLive.swift
//  DomainFeedbackShareImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainFeedbackShareInterface
import Foundation

// @lat: [[api#Feedback Share]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension FeedbackShareClient: @retroactive DependencyKey {
    public static var liveValue: FeedbackShareClient {
        @Dependency(\.authorizedNetworkClient) var network

        return FeedbackShareClient(
            status: { sessionId in
                try await FeedbackShareError.mapping {
                    try await network.api(
                        NetworkRequest(path: "/api/v1/feedback/sessions/\(sessionId)/share")
                    )
                }
            },
            create: { sessionId, axes in
                try await FeedbackShareError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/feedback/sessions/\(sessionId)/share",
                        body: CreateBody(axes: axes)
                    )
                    return try await network.api(request)
                }
            },
            makePrivate: { sessionId in
                try await FeedbackShareError.mapping {
                    let request = try NetworkRequest.json(
                        method: .patch,
                        path: "/api/v1/feedback/sessions/\(sessionId)/share",
                        body: UpdateBody(status: "PRIVATE")
                    )
                    try await network.api(request)
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

private struct CreateBody: Encodable {
    let axes: [String]
}

private struct UpdateBody: Encodable {
    let status: String
}
