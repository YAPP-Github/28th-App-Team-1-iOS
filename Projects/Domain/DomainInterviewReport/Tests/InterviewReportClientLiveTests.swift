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

    /// READY 응답 전문 — 스웨거 실계약 형태(카드 레드플래그·reason 별 하이라이트·발화 두 자리).
    private static let readyJSON = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "캐시 도입 결정의 이유를 구체적인 수치로 설명해주셨어요.",
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-07-21T13:00:00"},
            "cards": [{
                "axisOrder": 1, "depthLevel": 2,
                "questionText": "Q. 장애가 났을 때 가장 먼저 확인하는 지표는 무엇인가요?",
                "transcript": "저는 원래 디자인을 전공해서 협업 프로세스가 더 중요하다고 생각해요.",
                "highlightSpans": [{
                    "startIndex": 0, "endIndex": 36, "tone": "IMPROVE", "reason": "OFF_INTENT",
                    "title": "질문과 다른 주제로 답변",
                    "analysis": "장애 대응 지표가 아니라 협업 분위기에 대해 답변해 질문 의도와 어긋납니다.",
                    "followUpQuestions": [], "startSec": 80,
                    "answerTopicTitle": "협업 프로세스와 팀 분위기",
                    "questionIntentTitle": "장애 탐지 우선순위",
                    "questionIntent": "장애 발생 시 가장 먼저 확인하는 지표와 그 이유를 확인하는 질문입니다."
                }],
                "resolutionNotice": null,
                "cardRedFlagNotices": [{"type": "CONTRADICTION", "message": "답변 사이에 사실관계가 엇갈린 지점이 있었어요."}],
                "questionIntentTitle": "장애 탐지 우선순위",
                "questionIntent": "장애 발생 시 가장 먼저 확인하는 지표를 확인하는 질문입니다.",
                "scriptSegments": [
                    {"role": "INTERVIEWER", "text": "Q. 장애가 났을 때 가장 먼저 확인하는 지표는 무엇인가요?",
                     "startIndex": 0, "endIndex": 31, "startSec": 76, "endSec": 79.5},
                    {"role": "INTERVIEWEE", "text": "저는 원래 디자인을 전공해서 협업 프로세스가 더 중요하다고 생각해요.",
                     "startIndex": 0, "endIndex": 36, "startSec": 80, "endSec": 84.2}
                ]
            }],
            "script": [
                {"role": "INTERVIEWER", "text": "안녕하세요, 오늘 면접을 진행하겠습니다.", "startSec": 0, "endSec": 3.2},
                {"role": "INTERVIEWEE", "text": "저는 원래 디자인을 전공해서 협업 프로세스가 더 중요하다고 생각해요.", "startSec": 80, "endSec": 84.2}
            ],
            "guestFeedback": {
                "participantCount": 1,
                "guests": [{"alias": "지인", "attitudeRatings": [{"axis": "GAZE", "level": 3, "comment": null}]}]
            }
        }}
        """

    func test_report_READY응답의_카드와_하이라이트를_디코딩한다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions/7/report")
            XCTAssertEqual(request.method, .get)
            return Data(Self.readyJSON.utf8)
        }

        let report = try await client.report(7)

        XCTAssertEqual(report.status, .ready)
        XCTAssertEqual(report.cards?.count, 1)
        let span = report.cards?.first?.highlightSpans?.first
        XCTAssertEqual(span?.tone, "IMPROVE")
        XCTAssertEqual(span?.highlightReason, .offIntent)
        XCTAssertEqual(span?.answerTopicTitle, "협업 프로세스와 팀 분위기")
        XCTAssertEqual(span?.startSec, 80)
        XCTAssertEqual(report.cards?.first?.cardRedFlagNotices?.first?.type, "CONTRADICTION")
        XCTAssertEqual(report.cards?.first?.scriptSegments?.first?.role, .interviewer)
        XCTAssertEqual(report.script?.count, 2)
        XCTAssertEqual(report.guestFeedback?.participantCount, 1)
    }

    func test_report_카드레드플래그가_문자열배열로_와도_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "READY", "headline": "요약", "video": null,
            "cards": [{
                "axisOrder": 1, "depthLevel": 3,
                "questionText": "Q. 실제 역할은 무엇이었나요?",
                "transcript": "리뷰 위주였어요.",
                "highlightSpans": [],
                "resolutionNotice": null,
                "cardRedFlagNotices": ["면접 앞부분과 뒷부분의 답변이 서로 어긋나는 지점이 있었어요."],
                "questionIntentTitle": "실제 기여 범위",
                "questionIntent": "역할의 경계를 묻는 질문입니다.",
                "scriptSegments": []
            }],
            "script": null, "guestFeedback": null
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(54)

        let notice = report.cards?.first?.cardRedFlagNotices?.first
        XCTAssertNil(notice?.type)
        XCTAssertEqual(notice?.message, "면접 앞부분과 뒷부분의 답변이 서로 어긋나는 지점이 있었어요.")
    }

    func test_report_GENERATING이면_나머지필드가_nil이다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "GENERATING", "headline": null,
            "video": null, "cards": null, "script": null, "guestFeedback": null
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
