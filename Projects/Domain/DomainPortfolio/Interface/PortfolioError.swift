//
//  PortfolioError.swift
//  DomainPortfolioInterface
//
//  Created by EunseoKim on 26/07/23.
//

import DomainCommonInterface

/// Portfolio API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다 (AuthError 와 같은 원칙).
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#Portfolio]].
public enum PortfolioError: Error, Equatable, Sendable {
    /// INVALID_FILE_TYPE (400) — PDF 만 허용.
    case invalidFileType
    /// FILE_TOO_LARGE (400) — 20MB 초과.
    case fileTooLarge
    /// PAGE_COUNT_EXCEEDED (400) — 30페이지 초과.
    case pageCountExceeded
    /// INVALID_PDF_FILE (400) — 손상된 파일. 재선택 유도.
    case invalidPDFFile
    /// PORTFOLIO_ALREADY_EXISTS (409) — 계정당 1개 제한. 삭제 후 등록 UX.
    case alreadyExists
    /// PORTFOLIO_NOT_FOUND (404) — 없거나 본인 소유가 아님.
    case notFound
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}

// MARK: - 서버 코드 매핑 (공통 규칙·토큰 만료는 DomainAPIError 가 처리)

extension PortfolioError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "INVALID_FILE_TYPE": self = .invalidFileType
        case "FILE_TOO_LARGE": self = .fileTooLarge
        case "PAGE_COUNT_EXCEEDED": self = .pageCountExceeded
        case "INVALID_PDF_FILE": self = .invalidPDFFile
        case "PORTFOLIO_ALREADY_EXISTS": self = .alreadyExists
        case "PORTFOLIO_NOT_FOUND": self = .notFound
        default: return nil
        }
    }
}
