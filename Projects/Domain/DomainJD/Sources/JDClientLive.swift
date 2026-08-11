//
//  JDClientLive.swift
//  DomainJDImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainJDInterface
import Foundation

// @lat: [[api#JD]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension JDClient: @retroactive DependencyKey {
    public static var liveValue: JDClient {
        @Dependency(\.authorizedNetworkClient) var network

        return JDClient(
            validate: { jdURL in
                try await JDError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/jd/validate",
                        body: ValidateBody(jdUrl: jdURL)
                    )
                    return try await network.api(request)
                }
            }
        )
    }
}

private struct ValidateBody: Encodable {
    let jdUrl: String
}
