//
//  GuestFeedbackError.swift
//  DomainGuestFeedbackInterface
//
//  Created by EunseoKim on 26/07/23.
//

/// Guest Feedback API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// 무인증 API 라 sessionExpired 계열이 없다. 서버 코드 ↔ 케이스 매핑 표는 [[api#Guest Feedback]].
public enum GuestFeedbackError: Error, Equatable, Sendable {
    /// FEEDBACK_SHARE_TOKEN_NOT_FOUND (404) — 유효하지 않은 링크.
    case tokenNotFound
    /// FEEDBACK_SHARE_CLOSED (409) — 비공개·만료 링크 (진입 후 상태 변화 경합).
    case shareClosed
    /// FEEDBACK_CAPACITY_FULL (409) — 정원(4명) 마감.
    case capacityFull
    /// FEEDBACK_ALREADY_SUBMITTED (409) — 이 기기에서 이미 제출.
    case alreadySubmitted
    /// INCOMPLETE_RATINGS·INVALID_RATING_LEVEL·MISSING_DEVICE_ID (400)
    /// — `message` 는 그대로 사용자 노출 가능한 문구.
    case invalid(message: String)
    case networkFailure
    case serverUnavailable
    case unexpected
}
