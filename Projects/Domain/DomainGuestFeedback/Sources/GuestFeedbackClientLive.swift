//
//  GuestFeedbackClientLive.swift
//  DomainGuestFeedbackImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainGuestFeedbackInterface
import Foundation

// @lat: [[api#Guest Feedback]]
// depends-on: [[domain.map#네트워킹 인프라]]
// 무인증 API — Bearer 를 붙이는 AuthorizedNetworkClient 가 아니라 NetworkClient 를 직접 쓴다.
extension GuestFeedbackClient: @retroactive DependencyKey {
    public static var liveValue: GuestFeedbackClient {
        @Dependency(\.networkClient) var network

        return GuestFeedbackClient(
            entry: { token, deviceId in
                try await GuestFeedbackError.mapping {
                    let request = NetworkRequest(
                        path: "/api/v1/feedback/guest/\(token)",
                        headers: ["Device-Id": deviceId]
                    )
                    return try await network.api(request)
                }
            },
            submit: { token, deviceId, submission in
                try await GuestFeedbackError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/feedback/guest/\(token)/submissions",
                        headers: ["Device-Id": deviceId],
                        body: submission
                    )
                    return try await network.api(request)
                }
            }
        )
    }
}
