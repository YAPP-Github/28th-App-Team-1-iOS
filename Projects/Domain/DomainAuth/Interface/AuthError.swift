//
//  AuthError.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

import CoreNetworkInterface
import DomainCommonInterface

/// State가 다르게 반응해야 하는 경우의 수만큼만 둔 에러. 원인 상세는 매핑 함수에서 로깅한다.
public enum AuthError: Error, Equatable, Sendable {
    case cancelled
    case networkFailure
    case invalidCredential
    /// 미승격 서버 에러 원문 — 임시 노출 규칙(`ServerError.alertTitle/alertMessage`)으로 Alert 에 싣는다.
    /// 도메인 핸들링이 확정되면 전용 케이스로 승격.
    case server(ServerError)
    case serverUnavailable
    case sessionExpired
    case unexpected
}

// MARK: - 서버 코드 매핑 (공통 규칙·토큰 만료는 DomainAPIError 가 처리)

extension AuthError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "INVALID_CREDENTIAL", "SOCIAL_LOGIN_FAILED": self = .invalidCredential
        default: return nil
        }
    }

    /// 미승격 4xx 는 원문 그대로 동봉 — 임시 노출 규칙(2026-08-02).
    public static func fallback(unrecognized error: ServerError) -> AuthError {
        .server(error)
    }

    /// 공통 Alert(`serverAlertState`)가 읽을 원문.
    public var unrecognizedServerError: ServerError? {
        guard case let .server(error) = self else { return nil }
        return error
    }
}
