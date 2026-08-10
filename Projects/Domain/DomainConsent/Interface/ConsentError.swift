//
//  ConsentError.swift
//  DomainConsentInterface
//
//  Created by EunseoKim on 26/08/01.
//

import CoreNetworkInterface
import DomainCommonInterface

/// Consent API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// REQUIRED_CONSENT_MISSING·INVALID_CONSENT_ITEM 은 UI 가 필수 토글을 강제하면 도달할 수 없는
/// 클라이언트 결함이라 케이스로 승격하지 않는다(server 폴백으로 원문 노출). 매핑 표는 [[api#Consent]].
public enum ConsentError: Error, Equatable, Sendable {
    /// CONSENT_VERSION_MISMATCH (400) — 제출 사이에 약관이 개정됨. pending 재조회 후 재시도 유도.
    case versionMismatch
    /// VALIDATION_ERROR (400) — `message` 는 그대로 사용자 노출 가능한 문구.
    case invalid(message: String)
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

extension ConsentError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "CONSENT_VERSION_MISMATCH": self = .versionMismatch
        case "VALIDATION_ERROR": self = .invalid(message: message)
        default: return nil
        }
    }

    /// 미승격 4xx 는 원문 그대로 동봉 — 임시 노출 규칙(2026-08-02).
    public static func fallback(unrecognized error: ServerError) -> ConsentError {
        .server(error)
    }

    /// 공통 Alert(`serverAlertState`)가 읽을 원문.
    public var unrecognizedServerError: ServerError? {
        guard case let .server(error) = self else { return nil }
        return error
    }
}
