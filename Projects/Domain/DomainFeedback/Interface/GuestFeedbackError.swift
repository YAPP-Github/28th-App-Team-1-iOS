//
//  GuestFeedbackError.swift
//  DomainFeedbackInterface
//
//  Created by 서정원 on 26/07/20.
//

import Foundation

/// Guest Feedback API 의 도메인 에러 — 서버 코드 문자열은 Implementation 이 여기로 흡수해
/// Feature 에 새지 않는다. message 는 그대로 사용자 노출 가능한 한국어.
public enum GuestFeedbackError: Error, Equatable, Sendable {
    case closed             // FEEDBACK_SHARE_CLOSED — 비공개·무효화 링크
    case capacityFull       // FEEDBACK_CAPACITY_FULL — 면접당 4명 정원 마감
    case alreadySubmitted   // FEEDBACK_ALREADY_SUBMITTED — 이 기기 제출 완료
    case invalidToken       // FEEDBACK_SHARE_TOKEN_NOT_FOUND (404)
    case invalidSubmission  // INCOMPLETE_RATINGS · INVALID_RATING_LEVEL · MISSING_DEVICE_ID
    case underlying(message: String)
}

public extension GuestFeedbackError {
    /// PRD 확정 안내 문구.
    var userMessage: String {
        switch self {
        case .closed: "지금은 참여할 수 없는 링크예요."
        case .capacityFull: "이미 4분이 참여했어요."
        case .alreadySubmitted: "이미 제출하셨어요."
        case .invalidToken: "유효하지 않은 링크예요."
        case .invalidSubmission: "지정된 항목을 모두 평가해 주세요."
        case .underlying(let message): message
        }
    }

    /// Feature effect 의 catch 지점 — 도메인 에러는 그대로, 그 외(오프라인 등)는 일반 문구로 감싼다.
    static func wrap(_ error: any Error) -> GuestFeedbackError {
        (error as? GuestFeedbackError) ?? .underlying(message: "네트워크 연결을 확인해 주세요.")
    }
}
