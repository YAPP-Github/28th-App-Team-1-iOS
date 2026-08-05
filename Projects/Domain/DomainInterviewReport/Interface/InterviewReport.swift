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
    /// 채점 중 — headline·video·cards·script·guestFeedback 모두 nil
    case generating = "GENERATING"
    case ready = "READY"
    /// 분석 부족 — 채점된 범위의 카드만 내려온다
    case insufficientAnalysis = "INSUFFICIENT_ANALYSIS"
    case failed = "FAILED"
}

// MARK: - 구성 요소

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

/// 하이라이트 톤 — 대본 위 색 구분 (잘함/개선).
public enum HighlightTone: String, Decodable, Equatable, Sendable {
    case good = "GOOD"
    case improve = "IMPROVE"
}

/// 하이라이트 개선유형 — `followUpQuestions` 게이팅(PROBE_WORTHY)과 OFF_INTENT UI 분기의 키.
public enum HighlightReason: String, Decodable, Equatable, Sendable {
    /// 파고들 여지 — 이때만 `followUpQuestions` 가 비어 있지 않다
    case probeWorthy = "PROBE_WORTHY"
    /// 질문과 다른 답 — 전용 3필드(answerTopicTitle·questionIntentTitle·questionIntent) 동봉
    case offIntent = "OFF_INTENT"
    /// 짧고 얕음
    case shallow = "SHALLOW"
    /// 충분함
    case sufficient = "SUFFICIENT"
}

/// 발화 주체.
public enum InterviewScriptRole: String, Decodable, Equatable, Sendable {
    case interviewer = "INTERVIEWER"
    case interviewee = "INTERVIEWEE"
}

/// 문장 단위 발화 구간 — `startSec`/`endSec` 는 합성 영상(=녹화) 타임라인 기준(초).
/// 카드 `scriptSegments`(채점 턴 안의 문장, `startIndex`/`endIndex` 동봉)와
/// 최상위 `script`(세션 전체 타임라인, 인덱스 없음)가 같은 타입을 공유한다.
public struct InterviewScriptSegment: Decodable, Equatable, Sendable {
    public let role: InterviewScriptRole
    public let text: String
    /// 카드 변형에만 — 면접관 문장은 `questionText`, 면접자 문장은 `transcript` 문자열 기준 인덱스
    public let startIndex: Int?
    public let endIndex: Int?
    public let startSec: Double
    public let endSec: Double

    public init(
        role: InterviewScriptRole,
        text: String,
        startIndex: Int?,
        endIndex: Int?,
        startSec: Double,
        endSec: Double
    ) {
        self.role = role
        self.text = text
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startSec = startSec
        self.endSec = endSec
    }
}

/// 대본 위에 칠할 하이라이트 구간 (잘함/개선).
public struct HighlightSpan: Decodable, Equatable, Sendable {
    /// `transcript` 문자열 기준 시작/끝 인덱스
    public let startIndex: Int
    public let endIndex: Int
    public let tone: HighlightTone?
    public let reason: HighlightReason?
    /// 한 줄 제목
    public let title: String?
    /// 구간에 대한 분석 문구
    public let analysis: String?
    /// 꼬리질문 — `reason == .probeWorthy` 일 때만 비어 있지 않다 (그 외 빈 배열)
    public let followUpQuestions: [String]?
    /// 영상 앵커 — 구간 발화 시작 시각 (녹화 타임라인 기준 초)
    public let startSec: Double?
    /// OFF_INTENT 전용 — 답변이 실제로 다룬 주제 명사구 (그 외 reason 에선 nil)
    public let answerTopicTitle: String?
    /// OFF_INTENT 전용 — 카드 `questionIntentTitle` 복사값 (하이라이트만으로 의도↔답변 대비 구성용)
    public let questionIntentTitle: String?
    /// OFF_INTENT 전용 — 카드 `questionIntent` 복사값
    public let questionIntent: String?

    public init(
        startIndex: Int,
        endIndex: Int,
        tone: HighlightTone?,
        reason: HighlightReason?,
        title: String?,
        analysis: String?,
        followUpQuestions: [String]?,
        startSec: Double?,
        answerTopicTitle: String?,
        questionIntentTitle: String?,
        questionIntent: String?
    ) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.tone = tone
        self.reason = reason
        self.title = title
        self.analysis = analysis
        self.followUpQuestions = followUpQuestions
        self.startSec = startSec
        self.answerTopicTitle = answerTopicTitle
        self.questionIntentTitle = questionIntentTitle
        self.questionIntent = questionIntent
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
    /// 있으면 해상도 낮음 — 능력 판단성 분석 보류. 사유가 짧음·얕음이면 `highlightSpans` 는 빈 배열,
    /// 딴 답이면 `reason == .offIntent` 하이라이트 1개가 붙는다.
    public let resolutionNotice: String?
    /// 카드 단위 레드플래그 안내 문구 — 저장 5종 중 노출 3종(지어냄·모순·무결점 서사)만 중립 문구로.
    public let cardRedFlagNotices: [String]?
    /// 질문 의도 한 줄 제목
    public let questionIntentTitle: String?
    /// 질문 의도 설명
    public let questionIntent: String?
    /// 채점 대상 턴 안의 문장 단위 발화 — 면접관·면접자 문장이 `role` 로 구분되어 한 배열에 섞여 온다.
    public let scriptSegments: [InterviewScriptSegment]?

    public init(
        axisOrder: Int,
        depthLevel: Int,
        questionText: String?,
        transcript: String?,
        highlightSpans: [HighlightSpan]?,
        resolutionNotice: String?,
        cardRedFlagNotices: [String]?,
        questionIntentTitle: String?,
        questionIntent: String?,
        scriptSegments: [InterviewScriptSegment]?
    ) {
        self.axisOrder = axisOrder
        self.depthLevel = depthLevel
        self.questionText = questionText
        self.transcript = transcript
        self.highlightSpans = highlightSpans
        self.resolutionNotice = resolutionNotice
        self.cardRedFlagNotices = cardRedFlagNotices
        self.questionIntentTitle = questionIntentTitle
        self.questionIntent = questionIntent
        self.scriptSegments = scriptSegments
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

/// 지인 피드백 섹션 — 아무도 제출하지 않아도 `participantCount = 0, guests = []` 로 내려온다.
/// nil 은 `status == .generating` 일 때뿐.
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
/// 사용자용 화면(한 줄 요약 + 항목 카드 + 전체 대본 + 영상 메타 + 지인 피드백) 형태로 내려온다.
/// 레드플래그는 보고서 단위 안내 없이 걸린 카드의 `cardRedFlagNotices` 로만 노출된다.
public struct InterviewReport: Decodable, Equatable, Sendable {
    public let status: InterviewReportPhase
    /// 한 줄 요약. 심각 레드플래그가 있으면 칭찬 없는 중립 사실 요약으로 대체된다.
    public let headline: String?
    public let video: InterviewReportVideo?
    public let cards: [InterviewReportCard]?
    /// 면접 전체 대본 타임라인 — 첫 멘트부터 마무리까지 모든 발화를 `startSec` 오름차순 한 배열로.
    /// 영상 플레이어의 현재 발화 강조는 이것 하나만 훑는다.
    public let script: [InterviewScriptSegment]?
    public let guestFeedback: GuestFeedbackSection?

    public init(
        status: InterviewReportPhase,
        headline: String?,
        video: InterviewReportVideo?,
        cards: [InterviewReportCard]?,
        script: [InterviewScriptSegment]?,
        guestFeedback: GuestFeedbackSection?
    ) {
        self.status = status
        self.headline = headline
        self.video = video
        self.cards = cards
        self.script = script
        self.guestFeedback = guestFeedback
    }
}
