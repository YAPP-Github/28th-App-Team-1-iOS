//
//  ConsentClientLive.swift
//  DomainConsentImplementation
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainConsentInterface
import Foundation

// @lat: [[api#Consent]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension ConsentClient: @retroactive DependencyKey {
    public static var liveValue: ConsentClient {
        @Dependency(\.authorizedNetworkClient) var network

        return ConsentClient(
            pending: {
                try await ConsentError.mapping {
                    try await network.api(NetworkRequest(path: "/api/v1/consents/pending"))
                }
            },
            document: { item, version in
                try await ConsentError.mapping {
                    try await network.api(NetworkRequest(path: "/api/v1/consents/\(item)/versions/\(version)"))
                }
            },
            submit: { items in
                try await ConsentError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/consents",
                        body: SubmitBody(items: items)
                    )
                    try await network.api(request)
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

private struct SubmitBody: Encodable {
    let items: [ConsentSubmission]
}
