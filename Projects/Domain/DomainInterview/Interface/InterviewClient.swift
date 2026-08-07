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
    /// POST /interview/sessions/{id}/video/upload-url — S3 presigned PUT 대상 발급.
    /// `expiresInSeconds` 안에만 유효(만료 시 재발급). 저장 위치는 세션당 하나(재업로드 = 덮어쓰기).
    public var videoUploadURL: @Sendable (_ sessionId: Int) async throws -> InterviewVideoUploadTarget
    /// POST /interview/sessions/{id}/video/complete — 업로드 완료 확정. **S3 PUT 성공 후에만 호출**(호출처 책임). 멱등.
    /// `wrapUp == nil` 이면 바디 생략(조기 종료 등 마무리 멘트 없음).
    public var completeVideoUpload: @Sendable (_ sessionId: Int, _ wrapUp: InterviewVideoWrapUpSpan?) async throws -> Void
    /// 발급(videoUploadURL) → presigned PUT → complete 를 한 방으로 응집 — 호출처는 이 메서드 하나만 안다.
    /// 1시도 계약: 재시도(발급부터 재시작) 정책은 호출처 몫.
    public var uploadInterviewVideo: @Sendable (_ sessionId: Int, _ fileURL: URL, _ wrapUp: InterviewVideoWrapUpSpan?) async throws -> Void
    /// GET /interview/sessions — 내 면접 레포트 목록(마이페이지용). envelope `{ reports }` 는 Live 가 벗긴다.
    public var reportList: @Sendable () async throws -> [InterviewReportSummary]

    public init(
        createSession: @escaping @Sendable (InterviewConfig) async throws -> InterviewSessionCreated,
        sessionStatus: @escaping @Sendable (_ sessionId: Int) async throws -> InterviewSessionStatus,
        submitAnswer: @escaping @Sendable (_ sessionId: Int, AnswerSubmission) async throws -> AnswerResult,
        questionAudioStream: @escaping @Sendable (_ sessionId: Int, _ questionId: Int) async throws -> InterviewAudioStream,
        videoUploadURL: @escaping @Sendable (_ sessionId: Int) async throws -> InterviewVideoUploadTarget,
        completeVideoUpload: @escaping @Sendable (_ sessionId: Int, _ wrapUp: InterviewVideoWrapUpSpan?) async throws -> Void,
        uploadInterviewVideo: @escaping @Sendable (
            _ sessionId: Int,
            _ fileURL: URL,
            _ wrapUp: InterviewVideoWrapUpSpan?
        ) async throws -> Void,
        reportList: @escaping @Sendable () async throws -> [InterviewReportSummary]
    ) {
        self.createSession = createSession
        self.sessionStatus = sessionStatus
        self.submitAnswer = submitAnswer
        self.questionAudioStream = questionAudioStream
        self.videoUploadURL = videoUploadURL
        self.completeVideoUpload = completeVideoUpload
        self.uploadInterviewVideo = uploadInterviewVideo
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
            videoUploadURL: unimplemented("InterviewClient.videoUploadURL"),
            completeVideoUpload: unimplemented("InterviewClient.completeVideoUpload"),
            uploadInterviewVideo: unimplemented("InterviewClient.uploadInterviewVideo"),
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
            videoUploadURL: { sessionId in
                InterviewVideoUploadTarget(
                    uploadUrl: "preview://interview/\(sessionId)/video/upload",
                    contentType: "video/mp4",
                    expiresInSeconds: 600
                )
            },
            completeVideoUpload: { _, _ in },
            uploadInterviewVideo: { _, _, _ in },
            reportList: {
                [InterviewReportSummary(
                    sessionId: 1,
                    jobType: "BACKEND",
                    jobTypeLabel: "백엔드 개발자",
                    careerYears: 3,
                    interviewedAt: Date(timeIntervalSince1970: 1_782_000_000),
                    portfolioFileName: "portfolio.pdf",
                    portfolioDeleted: false,
                    jdUrl: nil,
                    reportStatus: .ready,
                    feedbackAvailable: true
                )]
            }
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
