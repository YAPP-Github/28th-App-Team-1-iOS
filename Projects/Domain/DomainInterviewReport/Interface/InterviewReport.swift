//
//  InterviewReport.swift
//  DomainInterviewReportInterface
//
//  Created by EunseoKim on 26/07/23.
//

import Foundation

// MARK: - 보고서 상태

/// 채점 파이프라인 진행 상태. GENERATING 이면 나머지 필드가 전부 nil — 폴링을 계속한다.
public enum InterviewReportPhase: String, Decodable, Equatable, Sendable {
    /// 채점 중 — headline·cards·video·guestFeedback 모두 nil
    case generating = "GENERATING"
    case ready = "READY"
    /// 분석 부족 — 채점된 범위의 카드만 내려온다
    case insufficientAnalysis = "INSUFFICIENT_ANALYSIS"
    case failed = "FAILED"
}

// MARK: - 구성 요소

/// 레드플래그 안내 (저장 5종 중 노출 3종 — 지어냄·모순·무결점 서사 — 만 중립 문구로 내려온다).
/// 심각한 레드플래그 유무는 `status` 가 아니라 이 배열이 비어 있는지로 판단한다.
public struct RedFlagNotice: Decodable, Equatable, Sendable {
    /// 서버 분류 코드 (예: "CONTRADICTION")
    public let type: String?
    /// 사용자 노출용 중립 문구
    public let message: String

    public init(type: String?, message: String) {
        self.type = type
        self.message = message
    }
}

/// 면접 영상 메타. 만료되면 `url` 이 nil — 카드의 대본·하이라이트는 그대로 유지된다.
public struct InterviewReportVideo: Decodable, Equatable, Sendable {
    public let url: String?
    public let expired: Bool?
    public let expiresAt: Date?

    public init(url: String?, expired: Bool?, expiresAt: Date?) {
        self.url = url
        self.expired = expired
        self.expiresAt = expiresAt
    }
}

/// 대본 위에 칠할 하이라이트 구간 (잘함/개선).
public struct HighlightSpan: Decodable, Equatable, Sendable {
    /// `transcript` 문자열 기준 시작/끝 인덱스
    public let startIndex: Int
    public let endIndex: Int
    /// 톤 — 스웨거 예시상 "GOOD" (개선 톤 문자열은 서버 예시 미제공, String 유지)
    public let tone: String?
    /// 구간에 대한 분석 문구
    public let analysis: String?

    public init(startIndex: Int, endIndex: Int, tone: String?, analysis: String?) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.tone = tone
        self.analysis = analysis
    }
}

/// 질문/답변 턴 하나당 카드 1장. 같은 항목(축) 카드끼리 `axisOrder` 가 같고
/// `depthLevel` 로 순서를 구분한다 — 화면 표시는 "질문 {axisOrder}-{depthLevel}" (예: 1-1, 1-2, 2-1).
public struct InterviewReportCard: Decodable, Equatable, Sendable {
    public let axisOrder: Int
    public let depthLevel: Int
    public let questionText: String?
    /// 답변 대본
    public let transcript: String?
    public let highlightSpans: [HighlightSpan]?
    /// 있으면 해상도 낮음 — 능력 판단성 분석 보류 상태, `highlightSpans` 는 빈 배열
    public let resolutionNotice: String?
    public let cardRedFlagNotices: [RedFlagNotice]?
    /// 질문 의도 설명
    public let questionIntent: String?

    public init(
        axisOrder: Int,
        depthLevel: Int,
        questionText: String?,
        transcript: String?,
        highlightSpans: [HighlightSpan]?,
        resolutionNotice: String?,
        cardRedFlagNotices: [RedFlagNotice]?,
        questionIntent: String?
    ) {
        self.axisOrder = axisOrder
        self.depthLevel = depthLevel
        self.questionText = questionText
        self.transcript = transcript
        self.highlightSpans = highlightSpans
        self.resolutionNotice = resolutionNotice
        self.cardRedFlagNotices = cardRedFlagNotices
        self.questionIntent = questionIntent
    }
}

/// 지인 한 명의 태도 평가 (보고서 표시용 — 제출측 계약은 [[api#Guest Feedback]]).
public struct GuestAttitudeRating: Decodable, Equatable, Sendable {
    /// 태도 항목 코드 (GAZE 등)
    public let axis: String
    /// 4단계 척도 (1=좋았어요 ~ 4=아쉬웠어요)
    public let level: Int?
    public let comment: String?

    public init(axis: String, level: Int?, comment: String?) {
        self.axis = axis
        self.level = level
        self.comment = comment
    }
}

/// 지인 리뷰 1건.
public struct GuestReview: Decodable, Equatable, Sendable {
    public let alias: String?
    public let attitudeRatings: [GuestAttitudeRating]?

    public init(alias: String?, attitudeRatings: [GuestAttitudeRating]?) {
        self.alias = alias
        self.attitudeRatings = attitudeRatings
    }
}

/// 지인 피드백 섹션 — 아무도 제출하지 않았으면 보고서에서 통째로 nil.
public struct GuestFeedbackSection: Decodable, Equatable, Sendable {
    public let participantCount: Int?
    public let guests: [GuestReview]?

    public init(participantCount: Int?, guests: [GuestReview]?) {
        self.participantCount = participantCount
        self.guests = guests
    }
}

// MARK: - 보고서

/// GET /interview/sessions/{id}/report 응답 — 점수·판정·천장 같은 내부 원값 없이
/// 사용자용 화면(한 줄 요약 + 항목 카드 + 영상 메타 + 지인 피드백) 형태로 내려온다.
public struct InterviewReport: Decodable, Equatable, Sendable {
    public let status: InterviewReportPhase
    /// 한 줄 요약. READY 인데 `redFlagNotices` 가 있으면 중립 사실 요약으로 대체된다.
    public let headline: String?
    public let redFlagNotices: [RedFlagNotice]?
    public let video: InterviewReportVideo?
    public let cards: [InterviewReportCard]?
    public let guestFeedback: GuestFeedbackSection?

    public init(
        status: InterviewReportPhase,
        headline: String?,
        redFlagNotices: [RedFlagNotice]?,
        video: InterviewReportVideo?,
        cards: [InterviewReportCard]?,
        guestFeedback: GuestFeedbackSection?
    ) {
        self.status = status
        self.headline = headline
        self.redFlagNotices = redFlagNotices
        self.video = video
        self.cards = cards
        self.guestFeedback = guestFeedback
    }
}
