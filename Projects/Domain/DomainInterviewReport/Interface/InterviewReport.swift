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
/// 보고서 단위 안내 줄은 없다 — **걸린 카드의 `cardRedFlagNotices` 로만** 노출된다.
/// 심각한 레드플래그가 있으면 `headline` 이 칭찬 없는 중립 사실 요약으로 대체된다.
public struct RedFlagNotice: Decodable, Equatable, Sendable {
    /// 서버 분류 코드 (예: "CONTRADICTION")
    public let type: String?
    /// 사용자 노출용 중립 문구
    public let message: String

    public init(type: String?, message: String) {
        self.type = type
        self.message = message
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case message
    }

    /// 서버가 안내를 **문구 문자열만** 내려주기도 하고 `{type, message}` 객체로 내려주기도 한다.
    /// 문자열이면 분류 코드 없이 `message` 로만 받는다.
    public init(from decoder: any Decoder) throws {
        if let message = try? decoder.singleValueContainer().decode(String.self) {
            self.type = nil
            self.message = message
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.message = try container.decode(String.self, forKey: .message)
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
///
/// `reason` 이 뒤따르는 필드의 유무를 정한다 — 파고들 여지(`PROBE_WORTHY`)면 `followUpQuestions`,
/// 딴 답(`OFF_INTENT`)이면 `answerTopicTitle`·`questionIntentTitle`·`questionIntent` 가 채워지고
/// 그 외 이유에서는 셋 다 비어 온다. 시트의 «다음 대비» 블록이 이 분기를 그대로 따른다.
public struct HighlightSpan: Decodable, Equatable, Sendable {
    /// `transcript` 문자열 기준 시작/끝 인덱스
    public let startIndex: Int
    public let endIndex: Int
    /// 톤 — 잘함 "GOOD" / 개선 "IMPROVE". 미지 값은 `highlightTone` 이 흡수한다.
    public let tone: String?
    /// 개선 유형 — `HighlightReason` 이 좁혀 받는다.
    public let reason: String?
    /// 하이라이트 한 줄 제목 (시트 진단 카드의 볼드 줄).
    public let title: String?
    /// 구간에 대한 분석 문구
    public let analysis: String?
    /// 꼬리질문 — `reason=PROBE_WORTHY` 일 때만 채워진다(그 외엔 빈 배열).
    public let followUpQuestions: [String]?
    /// 이 구간이 영상에서 시작하는 시각(초). 문자 인덱스만으로는 시간축을 알 수 없어
    /// 서버가 따로 내려준다 — 없으면 카드의 `scriptSegments` 에서 문장을 찾아 대신 쓴다
    /// (`InterviewReportCard.evidenceTime(for:)`).
    public let startSec: TimeInterval?
    /// 내 답변이 실제로 다룬 주제 명사구 — `reason=OFF_INTENT` 전용.
    public let answerTopicTitle: String?
    /// 질문이 물었던 것 — `reason=OFF_INTENT` 전용. 카드의 같은 이름 필드를 복사한 값이라
    /// «질문 의도 ↔ 내 답변» 대조를 구간 하나만 보고 세울 수 있다.
    public let questionIntentTitle: String?
    public let questionIntent: String?

    public init(
        startIndex: Int,
        endIndex: Int,
        tone: String?,
        reason: String? = nil,
        title: String? = nil,
        analysis: String?,
        followUpQuestions: [String]? = nil,
        startSec: TimeInterval? = nil,
        answerTopicTitle: String? = nil,
        questionIntentTitle: String? = nil,
        questionIntent: String? = nil
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
    /// 있으면 해상도 낮음 — 능력 판단성 분석 보류 상태, `highlightSpans` 는 빈 배열
    public let resolutionNotice: String?
    public let cardRedFlagNotices: [RedFlagNotice]?
    /// 질문 의도 제목 — 짧은 명사구(«장애 탐지 우선순위»).
    public let questionIntentTitle: String?
    /// 질문 의도 설명
    public let questionIntent: String?
    /// 이 질문 턴의 발화들 — 면접관 질문과 면접자 답변이 `role` 로 섞여 온다.
    /// 플레이어 진행바의 칸·구간 이동 단위는 이 중 면접자 발화다(`orderedSegments`).
    public let scriptSegments: [ScriptSegment]?

    public init(
        axisOrder: Int,
        depthLevel: Int,
        questionText: String?,
        transcript: String?,
        highlightSpans: [HighlightSpan]?,
        resolutionNotice: String?,
        cardRedFlagNotices: [RedFlagNotice]?,
        questionIntentTitle: String? = nil,
        questionIntent: String?,
        scriptSegments: [ScriptSegment]? = nil
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
    /// 한 줄 요약. READY 인데 심각 레드플래그가 있으면 중립 사실 요약으로 대체된다.
    public let headline: String?
    public let video: InterviewReportVideo?
    public let cards: [InterviewReportCard]?
    /// 세션 전체 발화 타임라인 — 첫 면접관 멘트부터 마무리까지 `startSec` 오름차순 한 배열.
    /// 카드의 `scriptSegments` 가 그 턴 안의 문장만 담는 것과 달리 이건 인사·마무리까지 들어 있다.
    public let script: [ScriptSegment]?
    public let guestFeedback: GuestFeedbackSection?

    public init(
        status: InterviewReportPhase,
        headline: String?,
        video: InterviewReportVideo?,
        cards: [InterviewReportCard]?,
        script: [ScriptSegment]? = nil,
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
