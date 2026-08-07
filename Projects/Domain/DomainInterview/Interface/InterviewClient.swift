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
    /// POST /interview/sessions/{id}/answers — 중복 제출은 `ANSWER_ALREADY_SUBMITTED`, 503 은 같은 요청 재시도 계약.
    public var submitAnswer: @Sendable (_ sessionId: Int, AnswerSubmission) async throws -> AnswerResult
    /// GET /interview/sessions/{id}/questions/{qid}/audio/stream 재생 정보 — AVPlayer 점진 재생용.
    public var questionAudioStream: @Sendable (_ sessionId: Int, _ questionId: Int) async throws -> InterviewAudioStream
    /// GET /interview/sessions/{id}/resume — 재개 가능 여부 조회. 상태를 바꾸지 않는다(hold 만료 정리는 서버 몫).
    /// 없거나 남의 세션이면 `sessionNotFound`.
    public var checkResume: @Sendable (_ sessionId: Int) async throws -> InterviewResumeCheck
    /// POST /interview/sessions/{id}/resume — 재개 확정(body 없음). 반환은 `submitAnswer` 와 같은 `AnswerResult` —
    /// 서버가 답변 제출과 같은 스키마를 쓰고 `answerId` 만 비우므로(이미 옵셔널) 턴 루프 처리기를 그대로 재사용한다.
    /// `checkResume` 을 건너뛰고 IN_PROGRESS 아닌 세션에 쏘면 409(`sessionAlreadyEnded`·`sessionNotStarted`·`sessionPreloadFailed`).
    public var confirmResume: @Sendable (_ sessionId: Int) async throws -> AnswerResult
    /// POST /interview/sessions/{id}/abandon — 면접 중단. `userExit` 은 진행분 리포트 생성 트리거,
    /// `networkDisconnect` 는 이용권 환급·리포트 없음. 중복 호출은 `sessionAlreadyEnded`(= 이미 중단 완료).
    public var abandonSession: @Sendable (_ sessionId: Int, _ cause: AbandonCause) async throws -> AbandonResult
    /// GET /interview/sessions — 내 면접 레포트 목록(홈 위젯②·마이페이지). envelope `{ reports }` 는 Live 가 벗긴다.
    public var reportList: @Sendable () async throws -> [InterviewReportSummary]

    public init(
        createSession: @escaping @Sendable (InterviewConfig) async throws -> InterviewSessionCreated,
        sessionStatus: @escaping @Sendable (_ sessionId: Int) async throws -> InterviewSessionStatus,
        submitAnswer: @escaping @Sendable (_ sessionId: Int, AnswerSubmission) async throws -> AnswerResult,
        questionAudioStream: @escaping @Sendable (_ sessionId: Int, _ questionId: Int) async throws -> InterviewAudioStream,
        checkResume: @escaping @Sendable (_ sessionId: Int) async throws -> InterviewResumeCheck,
        confirmResume: @escaping @Sendable (_ sessionId: Int) async throws -> AnswerResult,
        abandonSession: @escaping @Sendable (_ sessionId: Int, _ cause: AbandonCause) async throws -> AbandonResult,
        reportList: @escaping @Sendable () async throws -> [InterviewReportSummary]
    ) {
        self.createSession = createSession
        self.sessionStatus = sessionStatus
        self.submitAnswer = submitAnswer
        self.questionAudioStream = questionAudioStream
        self.checkResume = checkResume
        self.confirmResume = confirmResume
        self.abandonSession = abandonSession
        self.reportList = reportList
    }
}

extension InterviewClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: InterviewClient {
        InterviewClient(
            createSession: unimplemented("InterviewClient.createSession"),
            sessionStatus: unimplemented("InterviewClient.sessionStatus"),
            submitAnswer: unimplemented("InterviewClient.submitAnswer"),
            questionAudioStream: unimplemented("InterviewClient.questionAudioStream"),
            checkResume: unimplemented("InterviewClient.checkResume"),
            confirmResume: unimplemented("InterviewClient.confirmResume"),
            abandonSession: unimplemented("InterviewClient.abandonSession"),
            reportList: unimplemented("InterviewClient.reportList")
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
                    sessionEnded: false,
                    wrapUpMessage: nil,
                    endType: nil
                )
            },
            questionAudioStream: { sessionId, questionId in
                InterviewAudioStream(
                    url: URL(string: "preview://interview/\(sessionId)/questions/\(questionId)")!,
                    headers: [:]
                )
            },
            // 재개는 «가능» 을 그린다 — 2:12 경과(= 남은 시간이 있는 상태)라 홈의 [이어서 진행] 시안이 보인다.
            checkResume: { _ in
                InterviewResumeCheck(
                    resumeState: .resumable,
                    startedAt: Date(timeIntervalSince1970: 1_782_000_000),
                    elapsedSeconds: 132,
                    status: nil
                )
            },
            confirmResume: { _ in
                AnswerResult(
                    answerId: nil,
                    nextQuestion: NextQuestion(questionId: 21, isLast: false, turn: TurnInfo(turnLevel: 2, depthLevel: 0)),
                    sessionEnded: false,
                    wrapUpMessage: nil,
                    endType: nil
                )
            },
            abandonSession: { _, cause in
                AbandonResult(
                    status: .abandoned,
                    abandonCause: SessionAbandonCause(cause),
                    ticketOutcome: cause == .userExit ? .held : .released,
                    reportGenerating: cause == .userExit,
                    endedAt: Date(timeIntervalSince1970: 1_782_000_300)
                )
            },
            // 목록은 **여러 건**을 준다 — 홈 위젯② 는 펼친 행 1 + 접힌 행 N 이 시안이라 1건만 주면
            // 프리뷰가 접힌 행·스크롤·확장 자리를 못 보여준다. 상태도 섞어 상태 문구 행까지 그린다.
            reportList: { previewReports }
        )
    }

    /// 프리뷰 목록 5건 — 최신순, 상태 4종(준비·생성 중·분석 부족·실패)을 한 화면에서 본다.
    /// 시각은 KST 09:00 고정값이다(2026-07-11 → 07-07) — 프리뷰가 날마다 달라지지 않게.
    private static var previewReports: [InterviewReportSummary] {
        let day: TimeInterval = 86_400
        let latest: TimeInterval = 1_783_728_000
        let statuses: [ReportStatus] = [.ready, .ready, .generating, .insufficientAnalysis, .failed]
        return statuses.enumerated().map { index, status in
            InterviewReportSummary(
                sessionId: index + 1,
                jobType: "BACKEND",
                jobTypeLabel: "백엔드 개발자",
                careerYears: 3,
                interviewedAt: Date(timeIntervalSince1970: latest - day * TimeInterval(index)),
                portfolioFileName: "portfolio.pdf",
                portfolioDeleted: false,
                jdUrl: nil,
                reportStatus: status,
                feedbackAvailable: status == .ready
            )
        }
    }
}

public extension DependencyValues {
    var interviewClient: InterviewClient {
        get { self[InterviewClient.self] }
        set { self[InterviewClient.self] = newValue }
    }
}
