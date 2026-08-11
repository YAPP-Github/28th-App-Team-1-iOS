//
//  JDError.swift
//  DomainJDInterface
//
//  Created by EunseoKim on 26/07/23.
//

import DomainCommonInterface

/// JD API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다 (AuthError 와 같은 원칙).
/// 크롤링 실패(CRAWLING_FAILED 등)는 에러가 아니라 HTTP 200 + `JDValidation.valid == false` 로 온다.
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#JD]].
public enum JDError: Error, Equatable, Sendable {
    /// INVALID_JD_URL (400) — URL 형식 오류. 입력 필드 인라인 에러.
    case invalidURL
    /// JD_VALIDATION_LIMIT_EXCEEDED (429) — 1일 검증 5회 초과. jdText 직접 입력 폴백 유도.
    case dailyLimitExceeded
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}

// MARK: - 서버 코드 매핑 (공통 규칙·토큰 만료는 DomainAPIError 가 처리)

extension JDError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "INVALID_JD_URL": self = .invalidURL
        case "JD_VALIDATION_LIMIT_EXCEEDED": self = .dailyLimitExceeded
        default: return nil
        }
    }
}
