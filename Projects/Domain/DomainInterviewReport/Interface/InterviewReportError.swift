//
//  InterviewReportError.swift
//  DomainInterviewReportInterface
//
//  Created by EunseoKim on 26/07/23.
//

/// Interview Report API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다.
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#Interview Report]].
public enum InterviewReportError: Error, Equatable, Sendable {
    /// INTERVIEW_SESSION_NOT_FOUND (404) — 세션이 없거나 본인 소유가 아님.
    case sessionNotFound
    /// INTERVIEW_REPORT_NOT_FOUND (404) — 보고서가 아직 생성되지 않음 (재폴링/대기 안내).
    case reportNotFound
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}
