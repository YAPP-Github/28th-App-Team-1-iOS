//
//  InterviewClient.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import Foundation

// @lat: [[interview#Client 계약]]
// Feature 가 Interview 도메인에 접근하는 유일한 계약 — D14 면접 세션 API([[api#Interview]]) 미러링.
// testValue/previewValue 는 여기(Interface), liveValue 는 Implementation — App/Example 만 link (D4).
public struct InterviewClient: Sendable {
    /// POST /interview/sessions — 202 접수. 이용권(무료 3회) 소진 시 `NO_REMAINING_TICKET`.
    public var createSession: @Sendable (InterviewConfig) async throws -> InterviewSessionCreated
    /// GET /interview/sessions/{id}/status — 3~5초 간격 폴링. READY 면 요약 질문 TTS 동봉.
    public var sessionStatus: @Sendable (_ sessionId: Int) async throws -> InterviewSessionStatus
    /// POST /interview/sessions/{id}/answers — 현재 turnLevel=0(첫 턴) 전용. 중복 제출은 `ANSWER_ALREADY_SUBMITTED`.
    public var submitAnswer: @Sendable (_ sessionId: Int, AnswerSubmission) async throws -> AnswerResult
    /// GET /interview/sessions/{id}/questions/{qid}/audio/stream 재생 정보 — AVPlayer 점진 재생용.
    public var questionAudioStream: @Sendable (_ sessionId: Int, _ questionId: Int) async throws -> InterviewAudioStream

    public init(
        createSession: @escaping @Sendable (InterviewConfig) async throws -> InterviewSessionCreated,
        sessionStatus: @escaping @Sendable (_ sessionId: Int) async throws -> InterviewSessionStatus,
        submitAnswer: @escaping @Sendable (_ sessionId: Int, AnswerSubmission) async throws -> AnswerResult,
        questionAudioStream: @escaping @Sendable (_ sessionId: Int, _ questionId: Int) async throws -> InterviewAudioStream
    ) {
        self.createSession = createSession
        self.sessionStatus = sessionStatus
        self.submitAnswer = submitAnswer
        self.questionAudioStream = questionAudioStream
    }
}

extension InterviewClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: InterviewClient {
        InterviewClient(
            createSession: unimplemented("InterviewClient.createSession"),
            sessionStatus: unimplemented("InterviewClient.sessionStatus"),
            submitAnswer: unimplemented("InterviewClient.submitAnswer"),
            questionAudioStream: unimplemented("InterviewClient.questionAudioStream")
        )
    }

    /// Preview 용 — 네트워크 없이 준비 완료 세션 흐름을 그린다.
    public static var previewValue: InterviewClient {
        InterviewClient(
            createSession: { _ in
                InterviewSessionCreated(sessionId: 1, status: "PROCESSING", statusUrl: "/api/v1/interview/sessions/1/status")
            },
            sessionStatus: { _ in
                InterviewSessionStatus(
                    status: .ready,
                    startedAt: Date(timeIntervalSince1970: 1_782_000_000),
                    summaryQuestion: SummaryQuestion(questionId: 1, ttsAudio: nil, turn: TurnInfo(turnLevel: 0, depthLevel: 0))
                )
            },
            submitAnswer: { _, _ in
                AnswerResult(
                    answerId: 12,
                    nextQuestion: NextQuestion(questionId: 13, isLast: false, turn: TurnInfo(turnLevel: 1, depthLevel: 1)),
                    wrapUpMessage: nil,
                    reportId: nil
                )
            },
            questionAudioStream: { sessionId, questionId in
                InterviewAudioStream(
                    url: URL(string: "preview://interview/\(sessionId)/questions/\(questionId)")!,
                    headers: [:]
                )
            }
        )
    }
}

public extension DependencyValues {
    var interviewClient: InterviewClient {
        get { self[InterviewClient.self] }
        set { self[InterviewClient.self] = newValue }
    }
}
