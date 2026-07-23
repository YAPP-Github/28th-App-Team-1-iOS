//
//  GuestFeedbackModels.swift
//  DomainFeedbackInterface
//
//  Created by 서정원 on 26/07/20.
//

import Foundation

// @lat: [[feedback#Client 계약]]
// D14 Guest Feedback 응답 모델. 서버가 게이트·축을 추가해도 깨지지 않도록
// 게이트는 unknown 폴백, 축은 닫힌 enum 대신 String code 로 연다.

/// 링크 게이트 판정 — OPEN 만 평가 진행, FULL 은 시청 전용, 나머지는 차단.
public enum GuestFeedbackGate: Equatable, Sendable {
    case open
    case `private`
    case expired
    case full
    case alreadySubmitted
    case unknown
}

extension GuestFeedbackGate: Decodable {
    public init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "OPEN": self = .open
        case "PRIVATE": self = .private
        case "EXPIRED": self = .expired
        case "FULL": self = .full
        case "ALREADY_SUBMITTED": self = .alreadySubmitted
        default: self = .unknown
        }
    }
}

/// 태도 평가 축. 서버가 지정 항목만 내려주므로 code 를 그대로 보존해 제출에 돌려보낸다.
public struct AttitudeAxis: Equatable, Sendable, Identifiable, Decodable {
    public let code: String
    public let displayName: String

    public var id: String { code }

    public init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }
}

/// 질문 경계 — 영상 내 각 질문 턴의 시작 시각. 플레이어 점프 칩에 쓴다.
public struct QuestionBoundary: Equatable, Sendable {
    public let turnLevel: Int
    public let startAt: Double
    public let questionText: String?

    public init(turnLevel: Int, startAt: Double, questionText: String?) {
        self.turnLevel = turnLevel
        self.startAt = startAt
        self.questionText = questionText
    }
}

extension QuestionBoundary: Decodable {
    private enum CodingKeys: String, CodingKey { case turnLevel, startAt, questionText }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        turnLevel = try container.decodeIfPresent(Int.self, forKey: .turnLevel) ?? 0
        startAt = try container.decodeIfPresent(Double.self, forKey: .startAt) ?? 0
        questionText = try container.decodeIfPresent(String.self, forKey: .questionText)
    }
}

/// GET /feedback/guest/{token} 응답 — 게이트 + 평가에 필요한 전부.
public struct GuestFeedbackEntry: Equatable, Sendable {
    public var gate: GuestFeedbackGate
    public var requesterName: String?
    public var axes: [AttitudeAxis]
    public var videoURL: URL?
    public var questionBoundaries: [QuestionBoundary]
    public var submissionOpen: Bool

    public init(
        gate: GuestFeedbackGate,
        requesterName: String?,
        axes: [AttitudeAxis],
        videoURL: URL?,
        questionBoundaries: [QuestionBoundary],
        submissionOpen: Bool
    ) {
        self.gate = gate
        self.requesterName = requesterName
        self.axes = axes
        self.videoURL = videoURL
        self.questionBoundaries = questionBoundaries
        self.submissionOpen = submissionOpen
    }
}

extension GuestFeedbackEntry: Decodable {
    private enum CodingKeys: String, CodingKey {
        case gate, requesterName, axes, videoUrl, questionBoundaries, submissionOpen
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let gate = try container.decodeIfPresent(GuestFeedbackGate.self, forKey: .gate) ?? .unknown
        self.gate = gate
        requesterName = try container.decodeIfPresent(String.self, forKey: .requesterName)
        axes = try container.decodeIfPresent([AttitudeAxis].self, forKey: .axes) ?? []
        videoURL = try container.decodeIfPresent(String.self, forKey: .videoUrl).flatMap(URL.init(string:))
        questionBoundaries = try container.decodeIfPresent([QuestionBoundary].self, forKey: .questionBoundaries) ?? []
        submissionOpen = try container.decodeIfPresent(Bool.self, forKey: .submissionOpen) ?? (gate == .open)
    }
}

/// 항목 하나의 확정 응답 — 제출 payload 요소.
public struct GuestRating: Equatable, Sendable {
    public let axisCode: String
    public let level: Int          // 1(좋았어요) ~ 4(아쉬웠어요)
    public let comment: String?

    public init(axisCode: String, level: Int, comment: String?) {
        self.axisCode = axisCode
        self.level = level
        self.comment = comment
    }
}

/// POST /feedback/guest/{token}/submissions 요청 payload (서버 필드 매핑은 Implementation 책임).
public struct GuestSubmission: Equatable, Sendable {
    public let nickname: String?
    public let ratings: [GuestRating]
    public let overallFeedback: String?

    public init(nickname: String?, ratings: [GuestRating], overallFeedback: String?) {
        self.nickname = nickname
        self.ratings = ratings
        self.overallFeedback = overallFeedback
    }
}

/// 제출 성공 응답.
public struct GuestSubmissionReceipt: Equatable, Sendable {
    public let submissionID: Int
    public let submittedAt: Date

    public init(submissionID: Int, submittedAt: Date) {
        self.submissionID = submissionID
        self.submittedAt = submittedAt
    }
}

extension GuestSubmissionReceipt: Decodable {
    private enum CodingKeys: String, CodingKey {
        case submissionID = "submissionId"
        case submittedAt
    }
}

/// 항목 하나의 작성 중 상태 — level 미선택이어도 코멘트를 보존한다.
public struct RatingDraft: Codable, Equatable, Sendable {
    public var level: Int?
    public var comment: String

    public init(level: Int?, comment: String) {
        self.level = level
        self.comment = comment
    }
}

/// 게스트 임시저장(이어하기) — 클라 로컬 전제 (PRD 🔴서버 협의 3 미결, 현행 정책).
public struct GuestFeedbackDraft: Codable, Equatable, Sendable {
    public var nickname: String
    public var ratings: [String: RatingDraft]
    public var overallFeedback: String
    public var startedEvaluation: Bool

    public init(
        nickname: String,
        ratings: [String: RatingDraft],
        overallFeedback: String,
        startedEvaluation: Bool
    ) {
        self.nickname = nickname
        self.ratings = ratings
        self.overallFeedback = overallFeedback
        self.startedEvaluation = startedEvaluation
    }
}
