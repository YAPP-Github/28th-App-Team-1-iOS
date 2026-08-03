//
//  InterviewClientMock.swift
//  DomainInterviewTesting
//
//  Created by EunseoKim on 26/07/07.
//

import DomainInterviewInterface
import Foundation

public extension InterviewClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 준비 완료 세션의 해피패스를 그대로 돌려준다.
    static var mock: InterviewClient {
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
                    sessionEnded: false,
                    wrapUpMessage: nil,
                    endType: nil
                )
            },
            questionAudioStream: { sessionId, questionId in
                InterviewAudioStream(
                    url: URL(string: "mock://interview/\(sessionId)/questions/\(questionId)")!,
                    headers: [:]
                )
            },
            reportList: { [] }
        )
    }
}
