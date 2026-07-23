//
//  UserError.swift
//  DomainUserInterface
//
//  Created by EunseoKim on 26/07/23.
//

/// User API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다 (AuthError 와 같은 원칙).
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#User]].
public enum UserError: Error, Equatable, Sendable {
    /// USER_NOT_FOUND (404) — 토큰은 유효하나 회원이 삭제됨. 재로그인 유도.
    case userNotFound
    /// NAME_ALREADY_TAKEN (409) — 이름 인라인 검증 실패 표시.
    case nameAlreadyTaken
    /// INVALID_JOB_ROLE (400) — 직군 선택지 재조회(JobClient.jobs) 유도.
    case invalidJobRole
    /// VALIDATION_ERROR·CONSTRAINT_VIOLATION (400) — `message` 는 그대로 사용자 노출 가능한 문구.
    case invalid(message: String)
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}
