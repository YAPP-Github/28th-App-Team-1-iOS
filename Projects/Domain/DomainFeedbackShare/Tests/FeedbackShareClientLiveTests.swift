//
//  FeedbackShareClientLiveTests.swift
//  DomainFeedbackShareTests
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainFeedbackShareInterface
import XCTest
@testable import DomainFeedbackShareImplementation

final class FeedbackShareClientLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> FeedbackShareClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            FeedbackShareClient.liveValue
        }
    }

    func test_status_envelope을_벗겨_참여현황을_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "token": "t-1", "status": "ACTIVE", "axes": ["GAZE"], "submittedCount": 2,
            "videoExpiresAt": "2026-07-21T13:00:00", "requestedAt": "2026-07-19T13:00:00"
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/feedback/sessions/7/share")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let status = try await client.status(7)

        XCTAssertEqual(status.status, .active)
        XCTAssertEqual(status.submittedCount, 2)
        XCTAssertNotNil(status.videoExpiresAt)  // LocalDateTime 도 JSONDecoder.api 가 파싱
    }

    func test_create_axes를_body로_보내고_토큰을_받는다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/feedback/sessions/7/share")
            XCTAssertEqual(request.method, .post)
            let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: [String]]
            XCTAssertEqual(body?["axes"], ["GAZE", "VOICE"])
            return Data(#"{"success": true, "data": {"token": "t-new"}}"#.utf8)
        }

        let created = try await client.create(7, ["GAZE", "VOICE"])

        XCTAssertEqual(created.token, "t-new")
    }

    func test_create_활성링크존재409를_alreadyExists로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(409, Data(
                #"{"success": false, "code": "FEEDBACK_SHARE_ALREADY_EXISTS", "message": "이미 피드백 요청 링크가 있어요."}"#.utf8
            ))
        }

        do {
            _ = try await client.create(7, ["GAZE"])
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? FeedbackShareError, .alreadyExists)
        }
    }
}
