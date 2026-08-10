//
//  FeedbackShareError.swift
//  DomainFeedbackShareInterface
//
//  Created by EunseoKim on 26/07/23.
//

import CoreNetworkInterface
import DomainCommonInterface

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
    /// 미승격 서버 에러 원문 — 임시 노출 규칙(`ServerError.alertTitle/alertMessage`)으로 Alert 에 싣는다.
    /// 도메인 핸들링이 확정되면 전용 케이스로 승격.
    case server(ServerError)
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}

// MARK: - 서버 코드 매핑 (공통 규칙·토큰 만료는 DomainAPIError 가 처리)

extension FeedbackShareError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "FEEDBACK_SHARE_NOT_FOUND": self = .shareNotFound
        case "INTERVIEW_SESSION_NOT_FOUND": self = .sessionNotFound
        case "FEEDBACK_SHARE_ALREADY_EXISTS": self = .alreadyExists
        case "INVALID_SHARE_STATUS": self = .invalidStatusTransition
        case "EMPTY_ATTITUDE_AXES", "TOO_MANY_ATTITUDE_AXES", "INVALID_ATTITUDE_AXIS":
            self = .invalidAxes(message: message)
        default: return nil
        }
    }

    /// 미승격 4xx 는 원문 그대로 동봉 — 임시 노출 규칙(2026-08-02).
    public static func fallback(unrecognized error: ServerError) -> FeedbackShareError {
        .server(error)
    }

    /// 공통 Alert(`serverAlertState`)가 읽을 원문.
    public var unrecognizedServerError: ServerError? {
        guard case let .server(error) = self else { return nil }
        return error
    }
}
