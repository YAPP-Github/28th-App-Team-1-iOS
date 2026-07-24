//
//  FeedbackShareError.swift
//  DomainFeedbackShareInterface
//
//  Created by EunseoKim on 26/07/23.
//

/// Feedback Share API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#Feedback Share]].
public enum FeedbackShareError: Error, Equatable, Sendable {
    /// FEEDBACK_SHARE_NOT_FOUND (404) — 링크 미생성/삭제 상태.
    case shareNotFound
    /// INTERVIEW_SESSION_NOT_FOUND (404) — 세션이 없거나 본인 소유가 아님.
    case sessionNotFound
    /// FEEDBACK_SHARE_ALREADY_EXISTS (409) — 면접당 활성 링크 1개 제한 (재생성 미지원).
    case alreadyExists
    /// EMPTY_ATTITUDE_AXES·TOO_MANY_ATTITUDE_AXES·INVALID_ATTITUDE_AXIS (400)
    /// — `message` 는 그대로 사용자 노출 가능한 문구.
    case invalidAxes(message: String)
    /// INVALID_SHARE_STATUS (400) — 지원하지 않는 상태 전환 (현재 PRIVATE 만 지원).
    case invalidStatusTransition
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}
