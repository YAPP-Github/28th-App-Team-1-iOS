//
//  InterviewSession.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

// MARK: - 세션 생성 입력

/// 면접 세션 생성 입력 — Setup 위저드 산출물. (→ docs/work/ai-interview.md §4)
public struct InterviewConfig: Equatable, Sendable {
    public var portfolioId: UUID
    /// 서버 직군 Enum 값 (`JobClient.jobs` 의 `jobRole`, 예: "BACKEND") — 클라이언트에 직군 Enum 을 중복 정의하지 않는다
    public var jobRole: String
    /// 연차(년 단위)
    public var careerYears: Int
    /// JD 입력 — url/text 상호 배타 (서버 검증)
    public var jobDescription: JobDescriptionInput?
    /// 집중 프로젝트 설명 (10~300자, 포트폴리오 연관성 임베딩 검사 — `FREETEXT_NOT_RELEVANT`)
    public var freeText: String?

    public init(
        portfolioId: UUID,
        jobRole: String,
        careerYears: Int,
        jobDescription: JobDescriptionInput? = nil,
        freeText: String? = nil
    ) {
        self.portfolioId = portfolioId
        self.jobRole = jobRole
        self.careerYears = careerYears
        self.jobDescription = jobDescription
        self.freeText = freeText
    }
}

/// JD 입력 방식. `url` 은 `JDClient.validate` 로 사전 검증(캐싱)돼 있어야 한다 (`JD_NOT_VALIDATED`).
public enum JobDescriptionInput: Equatable, Sendable {
    case url(String)
    /// 200~3,000자 원문 직접 입력 (크롤링 실패 폴백)
    case text(String)
}

// MARK: - 세션 생성/준비 응답

/// POST /interview/sessions 202 응답 — PROCESSING 접수. 이후 `sessionStatus` 폴링(3~5초).
public struct InterviewSessionCreated: Decodable, Equatable, Sendable {
    public let sessionId: Int
    /// 생성 직후 항상 "PROCESSING"
    public let status: String?
    /// 준비 상태 폴링 URL
    public let statusUrl: String?

    public init(sessionId: Int, status: String?, statusUrl: String?) {
        self.sessionId = sessionId
        self.status = status
        self.statusUrl = statusUrl
    }
}

/// 세션 준비 상태. FAILED 시 이용권은 서버가 자동 환불한다.
public enum InterviewReadiness: String, Decodable, Equatable, Sendable {
    case processing = "PROCESSING"
    case ready = "READY"
    case failed = "FAILED"
}

/// GET /interview/sessions/{id}/status 응답 — READY 에 `startedAt`·요약 질문(TTS)이 동봉된다.
public struct InterviewSessionStatus: Decodable, Equatable, Sendable {
    public let status: InterviewReadiness
    public let startedAt: Date?
    public let summaryQuestion: SummaryQuestion?

    public init(status: InterviewReadiness, startedAt: Date?, summaryQuestion: SummaryQuestion?) {
        self.status = status
        self.startedAt = startedAt
        self.summaryQuestion = summaryQuestion
    }
}
