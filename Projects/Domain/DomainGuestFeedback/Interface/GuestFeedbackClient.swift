//
//  GuestFeedbackClient.swift
//  DomainGuestFeedbackInterface
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 게이트 판정 — 진입 화면 분기의 전부. `submissionOpen` 과 함께 내려온다.
public enum GuestFeedbackGate: String, Decodable, Equatable, Sendable {
    case open = "OPEN"
    /// 비공개·무효 링크
    case `private` = "PRIVATE"
    /// 영상 만료
    case expired = "EXPIRED"
    /// 정원(4명) 마감
    case full = "FULL"
    /// 이 기기에서 이미 제출 완료
    case alreadySubmitted = "ALREADY_SUBMITTED"
}

/// 지인이 평가할 태도 항목 (서버 지정 — 링크 생성 시 잠김).
public struct AttitudeAxis: Decodable, Equatable, Sendable {
    /// 항목 코드 (GAZE·EXPRESSION·POSTURE·GESTURE·VOICE) — 제출 시 이 값을 그대로 되돌려 보낸다
    public let code: String
    public let displayName: String

    public init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }
}

/// 질문 경계 — 영상에서 어떤 질문 구간인지 맥락 제공 (각 턴 시작 시각).
public struct QuestionBoundary: Decodable, Equatable, Sendable {
    /// 세션 전체 기준 순번
    public let turnLevel: Int
    /// 영상 내 질문 시작 시각(초)
    public let startAt: Double
    /// 질문 원문 (AI 피드백 아님)
    public let questionText: String?

    public init(turnLevel: Int, startAt: Double, questionText: String?) {
        self.turnLevel = turnLevel
        self.startAt = startAt
        self.questionText = questionText
    }
}

/// GET /feedback/guest/{token} 응답 — 링크 진입 시 영상·지정 항목·게이트 상태.
/// 최초 지인 조회 시 영상 삭제 예정 시각이 +7일 연장된다.
public struct GuestFeedbackEntry: Decodable, Equatable, Sendable {
    public let gate: GuestFeedbackGate
    /// 피드백을 요청한 사용자 이름/별명
    public let requesterName: String?
    public let axes: [AttitudeAxis]?
    /// 면접 영상 URL (S3 presigned). 영상 파이프라인 연결 전까지 nil.
    public let videoUrl: String?
    public let questionBoundaries: [QuestionBoundary]?
    /// 제출 가능 여부 — gate 가 OPEN 이 아니면 false.
    public let submissionOpen: Bool?

    public init(
        gate: GuestFeedbackGate,
        requesterName: String?,
        axes: [AttitudeAxis]?,
        videoUrl: String?,
        questionBoundaries: [QuestionBoundary]?,
        submissionOpen: Bool?
    ) {
        self.gate = gate
        self.requesterName = requesterName
        self.axes = axes
        self.videoUrl = videoUrl
        self.questionBoundaries = questionBoundaries
        self.submissionOpen = submissionOpen
    }
}

/// 항목별 척도 응답. 지정 항목을 하나라도 빠뜨리면 제출 불가 (`INCOMPLETE_RATINGS`).
public struct AttitudeRating: Encodable, Equatable, Sendable {
    /// `AttitudeAxis.code` 를 그대로 되돌려 보낸다
    public var axis: String
    /// 4단계 척도 (1=좋았어요 ~ 4=아쉬웠어요)
    public var level: Int
    /// '왜 그렇게 느꼈나요?' 코멘트 (선택)
    public var comment: String?

    public init(axis: String, level: Int, comment: String? = nil) {
        self.axis = axis
        self.level = level
        self.comment = comment
    }
}

/// POST /feedback/guest/{token}/submissions 입력. 제출은 확정 — 수정 불가, 동일 기기 재제출 차단.
public struct GuestFeedbackSubmission: Encodable, Equatable, Sendable {
    /// 지인 별칭 (선택)
    public var nickname: String?
    public var ratings: [AttitudeRating]

    public init(nickname: String? = nil, ratings: [AttitudeRating]) {
        self.nickname = nickname
        self.ratings = ratings
    }
}

/// 제출 완료 응답. 첫 제출 시 영상 삭제 예정 시각이 +30일 연장된다.
public struct GuestFeedbackReceipt: Decodable, Equatable, Sendable {
    public let submissionId: Int?
    public let submittedAt: Date?

    public init(submissionId: Int?, submittedAt: Date?) {
        self.submissionId = submissionId
        self.submittedAt = submittedAt
    }
}

// MARK: - Client

/// 지인 평가 API (D14 `/api/v1/feedback/guest/**`, 게스트측). **무인증** — 공유 토큰 + `Device-Id`
/// 헤더로 식별한다. `deviceId` 는 클라이언트가 생성해 로컬에 보관하는 기기 식별 값(중복 제출 방지).
/// 사용자측 공유 설정은 별도 도메인 — [[api#Feedback Share]].
// @lat: [[api#Guest Feedback]]
public struct GuestFeedbackClient: Sendable {
    /// GET /feedback/guest/{token} — 링크 진입, 게이트 판정 + 영상·지정 항목 수신.
    public var entry: @Sendable (_ token: String, _ deviceId: String) async throws -> GuestFeedbackEntry
    /// POST /feedback/guest/{token}/submissions — 지정 항목 전부를 4단계 척도로 제출.
    public var submit: @Sendable (
        _ token: String,
        _ deviceId: String,
        _ submission: GuestFeedbackSubmission
    ) async throws -> GuestFeedbackReceipt

    public init(
        entry: @escaping @Sendable (_ token: String, _ deviceId: String) async throws -> GuestFeedbackEntry,
        submit: @escaping @Sendable (
            _ token: String,
            _ deviceId: String,
            _ submission: GuestFeedbackSubmission
        ) async throws -> GuestFeedbackReceipt
    ) {
        self.entry = entry
        self.submit = submit
    }
}

extension GuestFeedbackClient: TestDependencyKey {
    public static var testValue: GuestFeedbackClient {
        GuestFeedbackClient(
            entry: unimplemented("GuestFeedbackClient.entry"),
            submit: unimplemented("GuestFeedbackClient.submit")
        )
    }

    public static var previewValue: GuestFeedbackClient {
        GuestFeedbackClient(
            entry: { _, _ in
                GuestFeedbackEntry(
                    gate: .open,
                    requesterName: "히릿",
                    axes: [
                        AttitudeAxis(code: "GAZE", displayName: "시선"),
                        AttitudeAxis(code: "VOICE", displayName: "목소리")
                    ],
                    videoUrl: nil,
                    questionBoundaries: [
                        QuestionBoundary(turnLevel: 0, startAt: 0, questionText: "자기소개를 부탁드려요.")
                    ],
                    submissionOpen: true
                )
            },
            submit: { _, _, _ in
                GuestFeedbackReceipt(
                    submissionId: 1,
                    submittedAt: Date(timeIntervalSince1970: 1_782_000_000)
                )
            }
        )
    }
}

public extension DependencyValues {
    var guestFeedbackClient: GuestFeedbackClient {
        get { self[GuestFeedbackClient.self] }
        set { self[GuestFeedbackClient.self] = newValue }
    }
}
