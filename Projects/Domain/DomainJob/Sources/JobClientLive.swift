//
//  JobClientLive.swift
//  DomainJobImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainJobInterface
import Foundation

// @lat: [[api#Job]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension JobClient: @retroactive DependencyKey {
    public static var liveValue: JobClient {
        @Dependency(\.authorizedNetworkClient) var network

        return JobClient(
            jobs: {
                let payload: JobListPayload = try await network.api(NetworkRequest(path: "/api/v1/jobs"))
                return payload.jobs
            }
        )
    }
}

private struct JobListPayload: Decodable, Sendable {
    let jobs: [Job]
}
