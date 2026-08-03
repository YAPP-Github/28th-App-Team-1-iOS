//
//  InterviewReportSummary.swift
//  DomainInterviewInterface
//
//  Created by 서정원 on 26/08/02.
//

import Foundation

/// 리포트 생성 상태 — 목록 셀 표시 분기용(GET /interview/sessions).
public enum ReportStatus: String, Decodable, Equatable, Sendable {
    case generating = "GENERATING"
    case ready = "READY"
    case insufficientAnalysis = "INSUFFICIENT_ANALYSIS"
    case failed = "FAILED"
}

/// 내 면접 레포트 목록 항목 — 마이페이지 배선(후속)용. 응답 envelope `{ reports: [...] }` 는 Live 가 벗긴다.
public struct InterviewReportSummary: Decodable, Equatable, Sendable, Identifiable {
    public var id: Int { sessionId }

    public let sessionId: Int
    /// 서버 직군 Enum 값(예: "BACKEND") — 세션 생성 시점의 프로필 스냅샷.
    public let jobType: String?
    /// 직군 표시명(예: "백엔드 개발자") — 셀은 이 값을 그대로 그린다.
    public let jobTypeLabel: String?
    public let careerYears: Int?
    public let interviewedAt: Date
    public let portfolioFileName: String?
    /// 포트폴리오가 삭제된 세션 — 파일명 대신 삭제 안내를 그린다.
    public let portfolioDeleted: Bool
    public let jdUrl: String?
    public let reportStatus: ReportStatus
    /// 지인 피드백 열람 가능 여부.
    public let feedbackAvailable: Bool

    public init(
        sessionId: Int,
        jobType: String?,
        jobTypeLabel: String?,
        careerYears: Int?,
        interviewedAt: Date,
        portfolioFileName: String?,
        portfolioDeleted: Bool,
        jdUrl: String?,
        reportStatus: ReportStatus,
        feedbackAvailable: Bool
    ) {
        self.sessionId = sessionId
        self.jobType = jobType
        self.jobTypeLabel = jobTypeLabel
        self.careerYears = careerYears
        self.interviewedAt = interviewedAt
        self.portfolioFileName = portfolioFileName
        self.portfolioDeleted = portfolioDeleted
        self.jdUrl = jdUrl
        self.reportStatus = reportStatus
        self.feedbackAvailable = feedbackAvailable
    }
}
