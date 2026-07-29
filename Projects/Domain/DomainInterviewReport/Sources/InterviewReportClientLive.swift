//
//  InterviewReportClientLive.swift
//  DomainInterviewReportImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainInterviewReportInterface
import Foundation

// @lat: [[api#Interview Report]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension InterviewReportClient: @retroactive DependencyKey {
    public static var liveValue: InterviewReportClient {
        @Dependency(\.authorizedNetworkClient) var network

        return InterviewReportClient(
            report: { sessionId in
                try await InterviewReportError.mapping {
                    try await network.api(
                        NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/report")
                    )
                }
            }
        )
    }
}
