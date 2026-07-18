//
//  JobClientLiveTests.swift
//  DomainJobTests
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainJobInterface
import XCTest
@testable import DomainJobImplementation

final class JobClientLiveTests: XCTestCase {
    func test_jobs_envelope을_벗겨_목록을_디코딩한다() async throws {
        let json = #"{"success": true, "data": {"jobs": [{"jobId": 1, "jobRole": "BACKEND", "label": "백엔드"}]}}"#
        let client = withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: { request in
                    XCTAssertEqual(request.path, "/api/v1/jobs")
                    XCTAssertEqual(request.method, .get)
                    return Data(json.utf8)
                },
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            JobClient.liveValue
        }

        let jobs = try await client.jobs()

        XCTAssertEqual(jobs, [Job(jobId: 1, jobRole: "BACKEND", label: "백엔드")])
    }
}
