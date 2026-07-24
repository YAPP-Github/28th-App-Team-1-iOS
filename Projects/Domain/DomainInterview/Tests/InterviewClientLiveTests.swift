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
    /// liveValue 가 AuthorizedNetworkClient "계약"만으로 동작하는지 — Core 구현(URLSession·토큰) 없이 검증한다.
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> InterviewClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { path in
                    AuthorizedResource(
                        url: URL(string: "http://stub.test\(path)")!,
                        headers: ["Authorization": "Bearer stub-token"]
                    )
                }
            )
        } operation: {
            InterviewClient.liveValue
        }
    }

    func test_createSession_jdUrl과_jdText를_상호배타로_인코딩한다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions")
            XCTAssertEqual(request.method, .post)
            let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: Any]
            XCTAssertEqual(body?["jobRole"] as? String, "BACKEND")
            XCTAssertEqual(body?["careerYears"] as? Int, 1)
            XCTAssertEqual(body?["jdUrl"] as? String, "https://example.com/careers/123")
            XCTAssertNil(body?["jdText"])  // 상호 배타 — url 입력이면 text 는 실리지 않는다
            return Data("""
            {"success": true, "data": {
                "sessionId": 7, "status": "PROCESSING", "statusUrl": "/api/v1/interview/sessions/7/status"
            }}
            """.utf8)
        }

        let created = try await client.createSession(InterviewConfig(
            portfolioId: UUID(),
            jobRole: "BACKEND",
            careerYears: 1,
            jobDescription: .url("https://example.com/careers/123")
        ))

        XCTAssertEqual(created.sessionId, 7)
        XCTAssertEqual(created.status, "PROCESSING")
    }

    func test_sessionStatus_READY응답의_LocalDateTime과_요약질문을_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "status": "READY",
            "startedAt": "2026-07-06T10:00:04",
            "summaryQuestion": {"questionId": 1, "ttsAudio": null, "turn": {"turnLevel": 0, "depthLevel": 0}}
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions/7/status")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let status = try await client.sessionStatus(7)

        XCTAssertEqual(status.status, .ready)
        XCTAssertNotNil(status.startedAt)  // LocalDateTime(타임존 없음)도 JSONDecoder.api 가 파싱
        XCTAssertEqual(status.summaryQuestion?.turn, TurnInfo(turnLevel: 0, depthLevel: 0))
    }

    func test_submitAnswer_메타데이터는_query로_오디오는_multipart로_보낸다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/interview/sessions/7/answers")
            XCTAssertEqual(request.method, .post)
            let query = Dictionary(uniqueKeysWithValues: request.queryItems.map { ($0.name, $0.value) })
            XCTAssertEqual(query["questionId"], "1")
            XCTAssertEqual(query["isWrapUp"], "false")
            XCTAssertTrue(request.headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
            let body = String(bytes: request.body ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains(#"name="audio""#))
            XCTAssertTrue(body.contains("mp3-bytes"))
            return Data("""
            {"success": true, "data": {
                "answerId": 12,
                "nextQuestion": {"questionId": 13, "isLast": false, "turn": {"turnLevel": 1, "depthLevel": 1}},
                "wrapUpMessage": null,
                "reportId": null
            }}
            """.utf8)
        }

        let result = try await client.submitAnswer(7, AnswerSubmission(
            questionId: 1,
            audio: Data("mp3-bytes".utf8),
            isWrapUp: false
        ))

        XCTAssertEqual(result.answerId, 12)
        XCTAssertEqual(result.nextQuestion?.questionId, 13)
    }

    func test_questionAudioStream_인증헤더가_실린_재생정보를_돌려준다() async throws {
        let client = makeClient { _ in Data() }

        let stream = try await client.questionAudioStream(7, 13)

        XCTAssertEqual(stream.url.absoluteString, "http://stub.test/api/v1/interview/sessions/7/questions/13/audio/stream")
        XCTAssertEqual(stream.headers["Authorization"], "Bearer stub-token")
    }

    func test_createSession_FREETEXT_NOT_RELEVANT_서버에러를_도메인에러로_승격한다() async {
        let body = Data(#"{"success": false, "code": "FREETEXT_NOT_RELEVANT", "message": "연관성이 낮아요."}"#.utf8)
        let client = makeClient { _ in throw NetworkError.statusCode(422, body) }

        do {
            _ = try await client.createSession(InterviewConfig(portfolioId: UUID(), jobRole: "BACKEND", careerYears: 1))
            XCTFail("InterviewError 가 나야 한다")
        } catch let error as InterviewError {
            XCTAssertEqual(error, .freeTextNotRelevant)
        } catch {
            XCTFail("InterviewError 가 아니라 \(error)")
        }
    }

    func test_createSession_미승격_서버에러는_server케이스로_승격한다() async {
        let body = Data(#"{"success": false, "code": "PORTFOLIO_NOT_READY", "message": "포폴 준비 중"}"#.utf8)
        let client = makeClient { _ in throw NetworkError.statusCode(409, body) }

        do {
            _ = try await client.createSession(InterviewConfig(portfolioId: UUID(), jobRole: "BACKEND", careerYears: 1))
            XCTFail("InterviewError 가 나야 한다")
        } catch let error as InterviewError {
            XCTAssertEqual(error, .server(code: "PORTFOLIO_NOT_READY", message: "포폴 준비 중"))
        } catch {
            XCTFail("InterviewError 가 아니라 \(error)")
        }
    }

    func test_createSession_이용권소진403을_noRemainingTicket으로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(403, Data(
                #"{"success": false, "code": "NO_REMAINING_TICKET", "message": "남은 이용권이 없어요."}"#.utf8
            ))
        }

        do {
            _ = try await client.createSession(InterviewConfig(portfolioId: UUID(), jobRole: "BACKEND", careerYears: 1))
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? InterviewError, .noRemainingTicket)
        }
    }

    func test_submitAnswer_중복제출409를_answerAlreadySubmitted로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(409, Data(
                #"{"success": false, "code": "ANSWER_ALREADY_SUBMITTED", "message": "이미 제출된 답변이에요."}"#.utf8
            ))
        }

        do {
            _ = try await client.submitAnswer(7, AnswerSubmission(questionId: 1))
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? InterviewError, .answerAlreadySubmitted)
        }
    }
}
