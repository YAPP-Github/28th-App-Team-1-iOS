//
//  GuestFeedbackClientLiveTests.swift
//  DomainFeedbackTests
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainFeedbackInterface
import Foundation
import Testing
@testable import DomainFeedbackImplementation

struct GuestFeedbackClientLiveTests {
    /// liveValue 가 NetworkClient "계약"만으로 동작하는지 — Core 구현(URLSession) 없이 검증한다.
    private func makeClient(
        deviceID: String = "device-1",
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> GuestFeedbackClient {
        withDependencies {
            $0.networkClient = NetworkClient(request: handler)
            $0.guestFeedbackLocalStore = .inMemory(deviceID: deviceID)
        } operation: {
            GuestFeedbackClient.liveValue
        }
    }

    @Test("enter 는 토큰 경로와 Device-Id 헤더로 GET 하고 envelope 를 벗겨 디코딩한다")
    func enterBuildsRequestAndDecodes() async throws {
        let client = makeClient { request in
            #expect(request.path == "/api/v1/feedback/guest/tok-123")
            #expect(request.method == .get)
            #expect(request.headers["Device-Id"] == "device-1")
            return Data("""
            {"success": true, "data": {
                "gate": "OPEN", "requesterName": "재원",
                "axes": [{"code": "GAZE", "displayName": "시선"}],
                "videoUrl": null,
                "questionBoundaries": [{"turnLevel": 1, "startAt": 42.5, "questionText": "자기소개"}],
                "submissionOpen": true
            }}
            """.utf8)
        }

        let entry = try await client.enter("tok-123")

        #expect(entry.gate == .open)
        #expect(entry.axes == [AttitudeAxis(code: "GAZE", displayName: "시선")])
        #expect(entry.questionBoundaries.first?.startAt == 42.5)
    }

    @Test("submit 은 서버 계약 필드명(axis·level)으로 인코딩해 POST 한다")
    func submitEncodesServerContract() async throws {
        let client = makeClient { request in
            #expect(request.path == "/api/v1/feedback/guest/tok-123/submissions")
            #expect(request.method == .post)
            #expect(request.headers["Device-Id"] == "device-1")
            #expect(request.headers["Content-Type"] == "application/json")

            let body = try JSONSerialization.jsonObject(with: request.body ?? Data()) as? [String: Any]
            #expect(body?["nickname"] as? String == "민지")
            #expect(body?["overallFeedback"] as? String == "전체적으로 좋았어요")
            let ratings = body?["ratings"] as? [[String: Any]]
            #expect(ratings?.count == 2)
            #expect(ratings?.first?["axis"] as? String == "GAZE")
            #expect(ratings?.first?["level"] as? Int == 2)
            #expect(ratings?.first?["comment"] as? String == "가끔 피해요")
            #expect(ratings?.last?["comment"] == nil)   // nil 코멘트는 필드 자체를 뺀다

            return Data(#"{"success": true, "data": {"submissionId": 7, "submittedAt": "2026-07-20T05:00:00Z"}}"#.utf8)
        }

        let receipt = try await client.submit("tok-123", GuestSubmission(
            nickname: "민지",
            ratings: [
                GuestRating(axisCode: "GAZE", level: 2, comment: "가끔 피해요"),
                GuestRating(axisCode: "VOICE", level: 1, comment: nil)
            ],
            overallFeedback: "전체적으로 좋았어요"
        ))

        #expect(receipt.submissionID == 7)
    }

    @Test(
        "서버 에러 코드를 도메인 에러로 매핑한다",
        arguments: [
            (409, "FEEDBACK_SHARE_CLOSED", GuestFeedbackError.closed),
            (409, "FEEDBACK_CAPACITY_FULL", GuestFeedbackError.capacityFull),
            (409, "FEEDBACK_ALREADY_SUBMITTED", GuestFeedbackError.alreadySubmitted),
            (404, "FEEDBACK_SHARE_TOKEN_NOT_FOUND", GuestFeedbackError.invalidToken),
            (400, "INCOMPLETE_RATINGS", GuestFeedbackError.invalidSubmission),
            (400, "INVALID_RATING_LEVEL", GuestFeedbackError.invalidSubmission),
            (400, "MISSING_DEVICE_ID", GuestFeedbackError.invalidSubmission)
        ]
    )
    func mapsServerErrorCodes(status: Int, code: String, expected: GuestFeedbackError) async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(status, Data(#"{"success": false, "code": "\#(code)", "message": "안내 문구"}"#.utf8))
        }

        await #expect(throws: expected) {
            _ = try await client.submit("tok-123", GuestSubmission(nickname: nil, ratings: [], overallFeedback: nil))
        }
    }

    @Test("모르는 서버 코드는 message 를 담은 underlying 으로 매핑한다")
    func mapsUnknownServerCodeToUnderlying() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(500, Data(#"{"success": false, "code": "SOMETHING_NEW", "message": "새 에러예요."}"#.utf8))
        }

        await #expect(throws: GuestFeedbackError.underlying(message: "새 에러예요.")) {
            _ = try await client.enter("tok-123")
        }
    }

    @Test("ServerError 가 아닌 실패(오프라인 등)는 도메인 에러로 바꾸지 않고 그대로 흘린다")
    func passesThroughNonServerErrors() async throws {
        struct Offline: Error, Equatable {}
        let client = makeClient { _ in throw Offline() }

        await #expect(throws: Offline.self) {
            _ = try await client.enter("tok-123")
        }
    }
}
