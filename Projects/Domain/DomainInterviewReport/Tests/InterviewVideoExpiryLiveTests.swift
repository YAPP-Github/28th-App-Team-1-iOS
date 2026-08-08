//
//  InterviewVideoExpiryLiveTests.swift
//  DomainInterviewReportTests
//
//  Created by 서정원 on 26/08/04.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewReportInterface
import XCTest
@testable import DomainInterviewReportImplementation

/// 영상 만료 조회(videoExpiry) 전용 — 리포트 조회 테스트와 클래스 분리 (InterviewReportClientLiveTests 가 type_body_length 임계 직전).
final class InterviewVideoExpiryLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> InterviewReportClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            InterviewReportClient.liveValue
        }
    }

    func test_videoExpiry_남은초와_만료여부를_디코딩한다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions/7/video/expiry")
            XCTAssertEqual(request.method, .get)
            return Data(#"{"success": true, "data": {"expiresInSeconds": 2591480, "expired": false}}"#.utf8)
        }

        let expiry = try await client.videoExpiry(7)

        XCTAssertEqual(expiry.expiresInSeconds, 2_591_480)
        XCTAssertFalse(expiry.expired)
    }

    func test_videoExpiry_영상레코드없음404를_videoNotFound로_매핑한다() async {
        // 세션은 있으나 업로드 완료 전 — 세션 자체가 없으면 INTERVIEW_SESSION_NOT_FOUND → sessionNotFound.
        let client = makeClient { _ in
            throw NetworkError.statusCode(404, Data(
                #"{"success": false, "code": "INTERVIEW_VIDEO_NOT_FOUND", "message": "면접 영상 정보를 찾을 수 없어요."}"#.utf8
            ))
        }

        do {
            _ = try await client.videoExpiry(7)
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? InterviewReportError, .videoNotFound)
        }
    }
}
