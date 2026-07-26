//
//  InterviewError.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/23.
//

import DomainCommonInterface

/// Interview API 에러 — State 가 다르게 반응해야 하는 경우의 수만큼만 둔다 (AuthError 와 같은 원칙).
/// Feature 는 Core 를 모르므로(레이어 규칙) 이 타입만 잡는다. (→ ai-interview.md §5 STEP6 Phase B)
/// 서버 코드 ↔ 케이스 매핑 표는 [[api#Interview]].
public enum InterviewError: Error, Equatable, Sendable {
    /// NO_REMAINING_TICKET (403) — 이용권 소진. 결제/안내 분기.
    case noRemainingTicket
    /// PORTFOLIO_NOT_FOUND (404) — 세션 생성 입력의 포트폴리오가 없거나 본인 소유가 아님.
    case portfolioNotFound
    /// PORTFOLIO_PROCESSING (400) — 포트폴리오 분석 중. READY 폴링 후 재시도 유도.
    case portfolioProcessing
    /// PORTFOLIO_UPLOAD_FAILED (400) — 포트폴리오 처리 실패. 재업로드 유도.
    case portfolioUploadFailed
    /// JD_NOT_VALIDATED (400) — jdUrl 이 사전 검증(JDClient.validate)을 통과하지 않음.
    case jdNotValidated
    /// FREETEXT_NOT_RELEVANT (400) — 집중 프로젝트가 포트폴리오와 연관성 부족(코사인 < 0.6). 재작성 유도.
    case freeTextNotRelevant
    /// INTERVIEW_SESSION_NOT_FOUND (404)
    case sessionNotFound
    /// QUESTION_NOT_FOUND (404)
    case questionNotFound
    /// ANSWER_ALREADY_SUBMITTED (409) — 재시도 차단. 다음 질문으로 진행.
    case answerAlreadySubmitted
    /// SESSION_ALREADY_ENDED (409) — 이미 종료된 세션. 보고서 화면으로 이탈.
    case sessionAlreadyEnded
    /// VALIDATION_ERROR·INVALID_JOB_ROLE·INVALID_CAREER_YEARS·INVALID_JD_LENGTH·
    /// INVALID_FREETEXT_LENGTH·INVALID_PLAYBACK_RANGE·INVALID_ANSWER_RANGE·
    /// INVALID_END_TYPE·INVALID_AUDIO_PRESENCE (400) — `message` 는 그대로 사용자 노출 가능.
    case invalid(message: String)
    /// 위 케이스로 승격되지 않은 그 외 서버 정의 에러(4xx) — 코드·사용자 노출 문구 동봉.
    /// 분기가 필요해지면 전용 케이스로 승격한다.
    case server(code: String, message: String)
    /// 재로그인 필요 (LOGIN_EXPIRED — 자동 재발급까지 실패한 뒤 도달)
    case sessionExpired
    case networkFailure
    case serverUnavailable
    case unexpected
}

// MARK: - 서버 코드 매핑 (공통 규칙·토큰 만료는 DomainAPIError 가 처리)

extension InterviewError: DomainAPIError {
    public init?(serverCode code: String, message: String) {
        switch code {
        case "NO_REMAINING_TICKET": self = .noRemainingTicket
        case "PORTFOLIO_NOT_FOUND": self = .portfolioNotFound
        case "PORTFOLIO_PROCESSING": self = .portfolioProcessing
        case "PORTFOLIO_UPLOAD_FAILED": self = .portfolioUploadFailed
        case "JD_NOT_VALIDATED": self = .jdNotValidated
        case "FREETEXT_NOT_RELEVANT": self = .freeTextNotRelevant
        case "INTERVIEW_SESSION_NOT_FOUND": self = .sessionNotFound
        case "QUESTION_NOT_FOUND": self = .questionNotFound
        case "ANSWER_ALREADY_SUBMITTED": self = .answerAlreadySubmitted
        case "SESSION_ALREADY_ENDED": self = .sessionAlreadyEnded
        case "VALIDATION_ERROR", "INVALID_JOB_ROLE", "INVALID_CAREER_YEARS",
             "INVALID_JD_LENGTH", "INVALID_FREETEXT_LENGTH", "INVALID_PLAYBACK_RANGE",
             "INVALID_ANSWER_RANGE", "INVALID_END_TYPE", "INVALID_AUDIO_PRESENCE":
            self = .invalid(message: message)
        default:
            return nil
        }
    }

    /// 미승격 코드는 원문 그대로 동봉 — 분기가 필요해지면 전용 케이스로 승격.
    public static func fallback(unrecognizedCode code: String, message: String) -> InterviewError {
        .server(code: code, message: message)
    }
}
