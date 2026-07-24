//
//  InterviewReportClientLiveTests.swift
//  DomainInterviewReportTests
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewReportInterface
import XCTest
@testable import DomainInterviewReportImplementation

final class InterviewReportClientLiveTests: XCTestCase {
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

    func test_report_READY응답의_카드와_하이라이트를_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "캐시 도입 결정의 이유를 구체적인 수치로 설명해주셨어요.",
            "redFlagNotices": [{"type": "CONTRADICTION", "message": "답변 사이에 사실관계가 엇갈린 지점이 있었어요."}],
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-07-21T13:00:00"},
            "cards": [{
                "axisOrder": 1, "depthLevel": 2,
                "questionText": "Q. 근본 원인은 무엇이었나요?",
                "transcript": "실제로 팀 프로젝트에서는 사용자 피드백을 50개 이상 모아 분석했어요.",
                "highlightSpans": [{"startIndex": 12, "endIndex": 48, "tone": "GOOD", "analysis": "구체적인 수치를 근거로 설명했습니다."}],
                "resolutionNotice": null,
                "cardRedFlagNotices": null,
                "questionIntent": "원인 진단 방법을 확인하는 질문입니다."
            }],
            "guestFeedback": {
                "participantCount": 1,
                "guests": [{"alias": "지인", "attitudeRatings": [{"axis": "GAZE", "level": 3, "comment": null}]}]
            }
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions/7/report")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let report = try await client.report(7)

        XCTAssertEqual(report.status, .ready)
        XCTAssertEqual(report.cards?.count, 1)
        XCTAssertEqual(report.cards?.first?.highlightSpans?.first?.tone, "GOOD")
        XCTAssertEqual(report.redFlagNotices?.first?.type, "CONTRADICTION")
        XCTAssertEqual(report.guestFeedback?.participantCount, 1)
    }

    func test_report_GENERATING이면_나머지필드가_nil이다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "GENERATING", "headline": null, "redFlagNotices": null,
            "video": null, "cards": null, "guestFeedback": null
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        XCTAssertEqual(report.status, .generating)
        XCTAssertNil(report.headline)
        XCTAssertNil(report.cards)
    }

    func test_report_보고서없음404를_reportNotFound로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(404, Data(
                #"{"success": false, "code": "INTERVIEW_REPORT_NOT_FOUND", "message": "면접 보고서를 찾을 수 없어요."}"#.utf8
            ))
        }

        do {
            _ = try await client.report(7)
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? InterviewReportError, .reportNotFound)
        }
    }
}
