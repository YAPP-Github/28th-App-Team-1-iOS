//
//  GuestFeedbackClientLiveTests.swift
//  DomainGuestFeedbackTests
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainGuestFeedbackInterface
import XCTest
@testable import DomainGuestFeedbackImplementation

final class GuestFeedbackClientLiveTests: XCTestCase {
    /// 무인증 API — AuthorizedNetworkClient 가 아니라 NetworkClient 를 스텁한다.
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> GuestFeedbackClient {
        withDependencies {
            $0.networkClient = NetworkClient(request: handler)
        } operation: {
            GuestFeedbackClient.liveValue
        }
    }

    func test_entry_DeviceId헤더를_싣고_게이트를_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "gate": "OPEN", "requesterName": "히릿",
            "axes": [{"code": "GAZE", "displayName": "시선"}],
            "videoUrl": null,
            "questionBoundaries": [{"turnLevel": 0, "startAt": 0.0, "questionText": "자기소개를 부탁드려요."}],
            "submissionOpen": true
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/feedback/guest/t-1")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headers["Device-Id"], "device-1")
            return Data(json.utf8)
        }

        let entry = try await client.entry("t-1", "device-1")

        XCTAssertEqual(entry.gate, .open)
        XCTAssertEqual(entry.axes?.first?.code, "GAZE")
        XCTAssertEqual(entry.submissionOpen, true)
    }

    func test_submit_ratings를_body로_보내고_접수증을_받는다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/feedback/guest/t-1/submissions")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.headers["Device-Id"], "device-1")
            let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: Any]
            let ratings = body?["ratings"] as? [[String: Any]]
            XCTAssertEqual(ratings?.first?["axis"] as? String, "GAZE")
            XCTAssertEqual(ratings?.first?["level"] as? Int, 2)
            return Data("""
            {"success": true, "data": {"submissionId": 11, "submittedAt": "2026-07-20T09:00:00"}}
            """.utf8)
        }

        let receipt = try await client.submit("t-1", "device-1", GuestFeedbackSubmission(
            nickname: "지인",
            ratings: [AttitudeRating(axis: "GAZE", level: 2)]
        ))

        XCTAssertEqual(receipt.submissionId, 11)
    }

    func test_submit_정원마감409를_capacityFull로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(409, Data(
                #"{"success": false, "code": "FEEDBACK_CAPACITY_FULL", "message": "이미 4분이 참여했어요."}"#.utf8
            ))
        }

        do {
            _ = try await client.submit("t-1", "device-1", GuestFeedbackSubmission(
                ratings: [AttitudeRating(axis: "GAZE", level: 1)]
            ))
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? GuestFeedbackError, .capacityFull)
        }
    }
}
