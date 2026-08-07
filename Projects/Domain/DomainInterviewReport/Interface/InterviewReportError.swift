//
//  InterviewReportError.swift
//  DomainInterviewReportInterface
//
//  Created by EunseoKim on 26/07/23.
//

import CoreNetworkInterface
import DomainCommonInterface

/// Interview Report API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#Interview Report]].
public enum InterviewReportError: Error, Equatable, Sendable {
    /// INTERVIEW_SESSION_NOT_FOUND (404) — 세션이 없거나 본인 소유가 아님.
    case sessionNotFound
    /// INTERVIEW_REPORT_NOT_FOUND (404) — 보고서가 아직 생성되지 않음 (재폴링/대기 안내).
    case reportNotFound
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

extension InterviewReportError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "INTERVIEW_SESSION_NOT_FOUND": self = .sessionNotFound
        case "INTERVIEW_REPORT_NOT_FOUND": self = .reportNotFound
        default: return nil
        }
    }

    /// 미승격 4xx 는 원문 그대로 동봉 — 임시 노출 규칙(2026-08-02).
    public static func fallback(unrecognized error: ServerError) -> InterviewReportError {
        .server(error)
    }

    /// 공통 Alert(`serverAlertState`)가 읽을 원문.
    public var unrecognizedServerError: ServerError? {
        guard case let .server(error) = self else { return nil }
        return error
    }
}
