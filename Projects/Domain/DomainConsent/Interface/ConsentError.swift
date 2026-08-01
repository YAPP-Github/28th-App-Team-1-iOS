//
//  ConsentError.swift
//  DomainConsentInterface
//
//  Created by EunseoKim on 26/08/01.
//

import DomainCommonInterface

/// Consent API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// REQUIRED_CONSENT_MISSING·INVALID_CONSENT_ITEM 은 UI 가 필수 토글을 강제하면 도달할 수 없는
/// 클라이언트 결함이라 케이스로 승격하지 않는다(unexpected 폴백). 매핑 표는 [[api#Consent]].
public enum ConsentError: Error, Equatable, Sendable {
    /// CONSENT_VERSION_MISMATCH (400) — 제출 사이에 약관이 개정됨. pending 재조회 후 재시도 유도.
    case versionMismatch
    /// VALIDATION_ERROR (400) — `message` 는 그대로 사용자 노출 가능한 문구.
    case invalid(message: String)
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
}
