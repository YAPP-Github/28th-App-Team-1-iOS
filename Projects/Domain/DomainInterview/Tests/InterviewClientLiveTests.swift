//
//  InterviewClientLiveTests.swift
//  DomainInterviewTests
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import XCTest
@testable import DomainInterviewImplementation

final class InterviewClientLiveTests: XCTestCase {
    /// liveValue 가 NetworkClient "계약"만으로 응답을 디코딩하는지 — Core 구현(URLSession) 없이 검증한다.
    func test_fetchInterviews_NetworkClient응답을_디코딩한다() async throws {
        let json = """
        [
            {"id": "interview-1", "title": "iOS 직무 면접 연습", "createdAt": "2025-06-16T00:00:00Z"}
        ]
        """
        let client = withDependencies {
            $0.networkClient = NetworkClient(request: { request in
                XCTAssertEqual(request.path, "/interviews")
                XCTAssertEqual(request.method, .get)
                return Data(json.utf8)
            })
        } operation: {
            InterviewClient.liveValue
        }

        let interviews = try await client.fetchInterviews()

        XCTAssertEqual(interviews.map(\.id), ["interview-1"])
        XCTAssertEqual(interviews.first?.title, "iOS 직무 면접 연습")
    }
}
