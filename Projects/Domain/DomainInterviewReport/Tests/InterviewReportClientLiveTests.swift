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

    // MARK: - 보고서 조회 (스웨거 named example 7종 디코딩)

    // swiftlint:disable:next function_body_length
    func test_report_정상_READY의_카드_하이라이트_전체대본을_디코딩한다() async throws {
        // 스웨거 "정상" 예시 — reason 게이팅(PROBE_WORTHY 꼬리질문·OFF_INTENT 3필드)까지 이 하나로 검증한다.
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해주셨어요.",
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-08-11T13:00:00"},
            "cards": [
                {
                    "axisOrder": 1, "depthLevel": 1,
                    "questionText": "Q. 결제 응답 속도를 개선하신 경험을 말씀해주세요. 무엇이 문제였나요?",
                    "transcript": "결제 화면에서 응답이 평균 800ms 정도로 느려서 사용자 이탈이 있었어요.",
                    "highlightSpans": [],
                    "resolutionNotice": null,
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "성능 저하 인지 수준",
                    "questionIntent": "성능 문제를 얼마나 구체적으로 인지했는지 확인하는 질문입니다.",
                    "scriptSegments": [
                        {"role": "INTERVIEWER", "text": "Q. 결제 응답 속도를 개선하신 경험을 말씀해주세요.", "startIndex": 0, "endIndex": 27, "startSec": 12.0, "endSec": 15.4},
                        {"role": "INTERVIEWER", "text": " 무엇이 문제였나요?", "startIndex": 27, "endIndex": 37, "startSec": 15.4, "endSec": 16.8},
                        {"role": "INTERVIEWEE", "text": "결제 화면에서 응답이 평균 800ms 정도로 느려서 사용자 이탈이 있었어요.", "startIndex": 0, "endIndex": 38, "startSec": 18.2, "endSec": 22.6}
                    ]
                },
                {
                    "axisOrder": 1, "depthLevel": 2,
                    "questionText": "Q. 응답이 느렸던 근본 원인은 무엇이었고, 어떻게 진단하셨나요?",
                    "transcript": "실제로 팀 프로젝트에서는 사용자 피드백을 50개 이상 모아 분석한 뒤...",
                    "highlightSpans": [
                        {"startIndex": 12, "endIndex": 48, "tone": "GOOD", "reason": "PROBE_WORTHY",
                         "title": "구체적 수치로 원인 설명",
                         "analysis": "구체적인 수치(50개, 분석 결과)를 근거로 원인을 설명해 신뢰도가 높습니다.",
                         "followUpQuestions": ["그 수치는 어떤 기간을 기준으로 집계한 건가요?"],
                         "startSec": 34.8}
                    ],
                    "resolutionNotice": null,
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "근본 원인 진단 방법",
                    "questionIntent": "근본 원인을 어떤 체계적인 방법으로 찾아냈는지 확인하는 질문입니다.",
                    "scriptSegments": []
                },
                {
                    "axisOrder": 3, "depthLevel": 1,
                    "questionText": "Q. 장애가 났을 때 가장 먼저 확인하는 지표는 무엇인가요?",
                    "transcript": "저는 원래 디자인을 전공해서 그런지 이런 장애 대응보다는 협업 프로세스나 팀 분위기가 더 중요하다고 생각해요.",
                    "highlightSpans": [
                        {"startIndex": 0, "endIndex": 52, "tone": "IMPROVE", "reason": "OFF_INTENT",
                         "title": "질문과 다른 주제로 답변",
                         "analysis": "장애 대응 지표가 아니라 협업 분위기에 대해 답변해 질문 의도와 어긋납니다.",
                         "followUpQuestions": [],
                         "startSec": 80.0,
                         "answerTopicTitle": "협업 프로세스와 팀 분위기",
                         "questionIntentTitle": "장애 탐지 우선순위",
                         "questionIntent": "장애 발생 시 가장 먼저 확인하는 지표와 그 이유를 확인하는 질문입니다."}
                    ],
                    "resolutionNotice": null,
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "장애 탐지 우선순위",
                    "questionIntent": "장애 발생 시 가장 먼저 확인하는 지표와 그 이유를 확인하는 질문입니다.",
                    "scriptSegments": []
                }
            ],
            "script": [
                {"role": "INTERVIEWER", "text": "안녕하세요, 오늘 면접을 진행하겠습니다.", "startSec": 0.0, "endSec": 3.2},
                {"role": "INTERVIEWER", "text": "Q. 결제 응답 속도를 개선하신 경험을 말씀해주세요.", "startSec": 12.0, "endSec": 15.4},
                {"role": "INTERVIEWEE", "text": "결제 화면에서 응답이 평균 800ms 정도로 느려서 사용자 이탈이 있었어요.", "startSec": 18.2, "endSec": 22.6},
                {"role": "INTERVIEWER", "text": "수고하셨습니다. 면접을 마치겠습니다.", "startSec": 70.5, "endSec": 73.9}
            ],
            "guestFeedback": {"participantCount": 0, "guests": []}
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions/7/report")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let report = try await client.report(7)

        XCTAssertEqual(report.status, .ready)
        XCTAssertEqual(report.cards?.count, 3)

        // 카드: 새 필드 questionIntentTitle + 카드 변형 scriptSegments(startIndex 동봉)
        let first = try XCTUnwrap(report.cards?.first)
        XCTAssertEqual(first.questionIntentTitle, "성능 저하 인지 수준")
        XCTAssertEqual(first.scriptSegments?.count, 3)
        XCTAssertEqual(first.scriptSegments?.first?.role, .interviewer)
        XCTAssertEqual(first.scriptSegments?.first?.startIndex, 0)
        XCTAssertEqual(first.scriptSegments?.first?.endIndex, 27)
        XCTAssertEqual(first.scriptSegments?.last?.role, .interviewee)

        // PROBE_WORTHY — 이때만 꼬리질문이 비어 있지 않다
        let probe = try XCTUnwrap(report.cards?[1].highlightSpans?.first)
        XCTAssertEqual(probe.tone, .good)
        XCTAssertEqual(probe.reason, .probeWorthy)
        XCTAssertEqual(probe.title, "구체적 수치로 원인 설명")
        XCTAssertEqual(probe.followUpQuestions, ["그 수치는 어떤 기간을 기준으로 집계한 건가요?"])
        XCTAssertEqual(probe.startSec, 34.8)
        XCTAssertNil(probe.answerTopicTitle)   // OFF_INTENT 전용 필드는 그 외 reason 에서 null

        // OFF_INTENT — 전용 3필드 동봉
        let offIntent = try XCTUnwrap(report.cards?[2].highlightSpans?.first)
        XCTAssertEqual(offIntent.tone, .improve)
        XCTAssertEqual(offIntent.reason, .offIntent)
        XCTAssertEqual(offIntent.followUpQuestions, [])
        XCTAssertEqual(offIntent.answerTopicTitle, "협업 프로세스와 팀 분위기")
        XCTAssertEqual(offIntent.questionIntentTitle, "장애 탐지 우선순위")
        XCTAssertEqual(offIntent.questionIntent, "장애 발생 시 가장 먼저 확인하는 지표와 그 이유를 확인하는 질문입니다.")

        // 최상위 script — 세션 전체 타임라인 (인덱스 없음, startSec 오름차순)
        XCTAssertEqual(report.script?.count, 4)
        XCTAssertEqual(report.script?.first?.role, .interviewer)
        XCTAssertNil(report.script?.first?.startIndex)
        XCTAssertEqual(report.script?.map(\.startSec), [0.0, 12.0, 18.2, 70.5])

        // 지인 0명이어도 섹션은 non-nil
        XCTAssertEqual(report.guestFeedback?.participantCount, 0)
        XCTAssertEqual(report.guestFeedback?.guests, [])
    }

    func test_report_로딩중이면_script포함_전필드가_nil이다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "GENERATING", "headline": null, "video": null,
            "cards": null, "script": null, "guestFeedback": null
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        XCTAssertEqual(report.status, .generating)
        XCTAssertNil(report.headline)
        XCTAssertNil(report.video)
        XCTAssertNil(report.cards)
        XCTAssertNil(report.script)
        XCTAssertNil(report.guestFeedback)
    }

    func test_report_해상도낮음카드는_보류사유와_OFF_INTENT하이라이트를_담는다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "이번 면접에서는 결제 응답 속도 개선 경험을 중심으로 이야기를 나눴어요.",
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-08-11T13:00:00"},
            "cards": [
                {
                    "axisOrder": 1, "depthLevel": 1,
                    "questionText": "Q. 장애가 났을 때 어디부터 확인하시나요?",
                    "transcript": "저희 팀에서 진행한 프로젝트는 사용자 피드백을 반영해서...",
                    "highlightSpans": [],
                    "resolutionNotice": "답변이 짧고 얕아 이 항목은 능력 판단을 보류했어요.",
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "장애 원인 좁히기",
                    "questionIntent": "장애가 났을 때 원인을 어떻게 좁혀나가는지 확인하는 질문입니다.",
                    "scriptSegments": []
                },
                {
                    "axisOrder": 2, "depthLevel": 1,
                    "questionText": "Q. 트래픽이 몰릴 때 병목이 어디라고 보시나요?",
                    "transcript": "사실 저는 기술보다 팀워크가 더 중요하다고 생각해서 그쪽 이야기를 하고 싶어요.",
                    "highlightSpans": [
                        {"startIndex": 0, "endIndex": 41, "tone": "IMPROVE", "reason": "OFF_INTENT",
                         "title": "질문과 다른 주제로 답변",
                         "analysis": "병목 지점을 묻는 질문에 팀워크 이야기를 해 질문 의도와 어긋납니다.",
                         "followUpQuestions": [],
                         "startSec": 30.0,
                         "answerTopicTitle": "팀워크의 중요성",
                         "questionIntentTitle": "트래픽 병목 판단",
                         "questionIntent": "트래픽이 몰릴 때 어디가 병목이 되는지 판단하는 질문입니다."}
                    ],
                    "resolutionNotice": "질문과 다른 답변이 있어 이 항목은 능력 판단을 보류했어요.",
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "트래픽 병목 판단",
                    "questionIntent": "트래픽이 몰릴 때 어디가 병목이 되는지 판단하는 질문입니다.",
                    "scriptSegments": []
                }
            ],
            "script": [],
            "guestFeedback": {"participantCount": 0, "guests": []}
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        // 짧음·얕음 사유 — 하이라이트 빈 배열
        XCTAssertEqual(report.cards?[0].resolutionNotice, "답변이 짧고 얕아 이 항목은 능력 판단을 보류했어요.")
        XCTAssertEqual(report.cards?[0].highlightSpans, [])
        // 딴 답 사유 — OFF_INTENT 하이라이트 1개
        XCTAssertEqual(report.cards?[1].highlightSpans?.count, 1)
        XCTAssertEqual(report.cards?[1].highlightSpans?.first?.reason, .offIntent)
        XCTAssertEqual(report.cards?[1].highlightSpans?.first?.answerTopicTitle, "팀워크의 중요성")
    }

    func test_report_분석부족_SHALLOW하이라이트를_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "INSUFFICIENT_ANALYSIS",
            "headline": "이번 면접의 답변이 충분하지 않아요. 다음 면접 연습 때는 조금 더 충분한 답변을 말씀해주세요.",
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-08-11T13:00:00"},
            "cards": [
                {
                    "axisOrder": 1, "depthLevel": 1,
                    "questionText": "Q. 최근에 성능을 개선한 경험이 있나요?",
                    "transcript": "네, 있습니다. 캐시를 좀 썼어요.",
                    "highlightSpans": [
                        {"startIndex": 8, "endIndex": 16, "tone": "IMPROVE", "reason": "SHALLOW",
                         "title": "근거·수치 부족",
                         "analysis": "무엇을 어떻게 개선했는지 구체적 근거나 수치가 없어 깊이가 부족합니다.",
                         "followUpQuestions": [],
                         "startSec": 15.0}
                    ],
                    "resolutionNotice": null,
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "성능 개선 경험",
                    "questionIntent": "성능 문제를 어떻게 정의하고 개선했는지 확인하는 질문입니다.",
                    "scriptSegments": []
                }
            ],
            "script": [],
            "guestFeedback": {"participantCount": 0, "guests": []}
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        XCTAssertEqual(report.status, .insufficientAnalysis)
        let span = try XCTUnwrap(report.cards?.first?.highlightSpans?.first)
        XCTAssertEqual(span.reason, .shallow)
        XCTAssertEqual(span.tone, .improve)
        XCTAssertEqual(span.followUpQuestions, [])
    }

    func test_report_레드플래그는_카드단위_문자열배열로_내려온다() async throws {
        // 현행 계약: 보고서 단위 redFlagNotices 없음 — 걸린 카드의 cardRedFlagNotices([String])로만 노출.
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "이번 면접에서는 캐시 도입 결정과 장애 대응 경험을 중심으로 이야기를 나눴어요.",
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-08-11T13:00:00"},
            "cards": [
                {
                    "axisOrder": 1, "depthLevel": 1,
                    "questionText": "Q. 그 결정을 내리기까지 어떤 대안들을 검토하셨나요?",
                    "transcript": "제가 Redis 캐시를 도입했습니다...",
                    "highlightSpans": [],
                    "resolutionNotice": null,
                    "cardRedFlagNotices": ["면접 앞부분과 뒷부분의 답변이 서로 어긋나는 지점이 있었어요."],
                    "questionIntentTitle": "의사결정 기여도",
                    "questionIntent": "의사결정 과정에서 본인의 역할과 기여를 확인하는 질문입니다.",
                    "scriptSegments": []
                }
            ],
            "script": [],
            "guestFeedback": {"participantCount": 0, "guests": []}
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        XCTAssertEqual(
            report.cards?.first?.cardRedFlagNotices,
            ["면접 앞부분과 뒷부분의 답변이 서로 어긋나는 지점이 있었어요."]
        )
    }

    func test_report_지인피드백_참여자와_태도평가를_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해주셨어요.",
            "video": {"url": "https://cdn.example.com/videos/abc.mp4", "expired": false, "expiresAt": "2026-08-04T13:00:00"},
            "cards": [],
            "script": [],
            "guestFeedback": {
                "participantCount": 2,
                "guests": [
                    {"alias": "허자연", "attitudeRatings": [
                        {"axis": "GAZE", "level": 3, "comment": "꼬리질문에서 눈빛이 흔들려서 자신감이 없어 보였어요."},
                        {"axis": "EXPRESSION", "level": 4, "comment": null}
                    ]},
                    {"alias": "박민주", "attitudeRatings": [
                        {"axis": "GAZE", "level": 2, "comment": null}
                    ]}
                ]
            }
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        XCTAssertEqual(report.guestFeedback?.participantCount, 2)
        XCTAssertEqual(report.guestFeedback?.guests?.count, 2)
        let firstGuest = try XCTUnwrap(report.guestFeedback?.guests?.first)
        XCTAssertEqual(firstGuest.alias, "허자연")
        XCTAssertEqual(firstGuest.attitudeRatings?.first?.axis, "GAZE")
        XCTAssertEqual(firstGuest.attitudeRatings?.first?.level, 3)
        XCTAssertNil(firstGuest.attitudeRatings?.last?.comment)
    }

    func test_report_영상만료면_url만_nil이고_대본은_유지된다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "headline": "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해주셨어요.",
            "video": {"url": null, "expired": true, "expiresAt": "2026-07-25T13:00:00"},
            "cards": [
                {
                    "axisOrder": 1, "depthLevel": 1,
                    "questionText": "Q. 결제 응답 속도를 개선하신 경험을 말씀해주세요.",
                    "transcript": "결제 화면에서 응답이 평균 800ms 정도로 느려서 사용자 이탈이 있었어요.",
                    "highlightSpans": [
                        {"startIndex": 0, "endIndex": 20, "tone": "GOOD", "reason": "SUFFICIENT",
                         "title": "문제 상황 구체적으로 설명",
                         "analysis": "응답 지연 수치와 그 영향을 구체적으로 설명했습니다.",
                         "followUpQuestions": [],
                         "startSec": 18.2}
                    ],
                    "resolutionNotice": null,
                    "cardRedFlagNotices": null,
                    "questionIntentTitle": "성능 저하 인지 수준",
                    "questionIntent": "성능 문제를 얼마나 구체적으로 인지했는지 확인하는 질문입니다.",
                    "scriptSegments": []
                }
            ],
            "script": [
                {"role": "INTERVIEWER", "text": "Q. 결제 응답 속도를 개선하신 경험을 말씀해주세요.", "startSec": 12.0, "endSec": 15.4},
                {"role": "INTERVIEWEE", "text": "결제 화면에서 응답이 평균 800ms 정도로 느려서 사용자 이탈이 있었어요.", "startSec": 18.2, "endSec": 22.6}
            ],
            "guestFeedback": {"participantCount": 0, "guests": []}
        }}
        """
        let client = makeClient { _ in Data(json.utf8) }

        let report = try await client.report(7)

        XCTAssertNil(report.video?.url)
        XCTAssertEqual(report.video?.expired, true)
        XCTAssertEqual(report.cards?.count, 1)   // 대본·하이라이트는 유지
        XCTAssertEqual(report.cards?.first?.highlightSpans?.first?.reason, .sufficient)
        XCTAssertEqual(report.script?.count, 2)
    }

    // MARK: - 에러 매핑

    func test_report_보고서없음404를_reportNotFound로_매핑한다() async throws {
        // INTERVIEW_REPORT_NOT_FOUND 는 현행 스웨거에서 빠졌지만(미생성 = GENERATING 응답) 매핑은 방어적으로 유지한다.
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
