//
//  InterviewAbandon.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/08/08.
//

import Foundation

/// 중단 사유(요청). 응답의 `SessionAbandonCause` 와 값 집합이 달라 분리 유지한다
/// (`AnswerEndType` ↔ `SessionEndType` 과 같은 이유).
public enum AbandonCause: String, Equatable, Sendable {
    /// 사용자가 면접을 빠져나감 — 진행분으로 리포트 생성 트리거(이용권 HELD, 리포트 성공 시 차감 확정).
    case userExit = "USER_EXIT"
    /// 네트워크 단절로 진행 불가 — 이용권 환급(RELEASED)·리포트 미생성.
    case networkDisconnect = "NETWORK_DISCONNECT"
}

/// 중단 사유(응답) — 요청에 없는 `holdExpired` 를 포함한다.
public enum SessionAbandonCause: String, Decodable, Equatable, Sendable {
    case userExit = "USER_EXIT"
    case networkDisconnect = "NETWORK_DISCONNECT"
    /// 이용권 예약(hold) 20분 만료 — 서버가 재개 조회/확정 안에서 스스로 전환시킨 경우.
    /// 요청으로 보내면 `INVALID_ABANDON_CAUSE`(400) 라 `AbandonCause` 에는 없다.
    case holdExpired = "HOLD_EXPIRED"
}

public extension SessionAbandonCause {
    /// 요청 사유 → 응답 사유 승격 (mock·preview 가 요청을 그대로 되비칠 때 쓴다).
    init(_ requested: AbandonCause) {
        switch requested {
        case .userExit: self = .userExit
        case .networkDisconnect: self = .networkDisconnect
        }
    }
}

/// 이용권 처리 결과 — HELD 는 리포트 생성 성공 시 차감 확정, RELEASED 는 즉시 환급.
public enum TicketOutcome: String, Decodable, Equatable, Sendable {
    case held = "HELD"
    case released = "RELEASED"
}

/// POST /interview/sessions/{id}/abandon 응답. 필드 확정 전이라 전부 옵셔널로 둔다 —
/// 중복 호출은 200 이 아니라 `SESSION_ALREADY_ENDED`(409) 이므로 «이미 중단 완료» 판정은 에러 쪽이다.
public struct AbandonResult: Decodable, Equatable, Sendable {
    public let status: InterviewEndedStatus?
    public let abandonCause: SessionAbandonCause?
    public let ticketOutcome: TicketOutcome?
    /// 리포트 생성이 트리거됐는지 — `userExit` 만 true. 리포트 대기 화면으로 보낼지의 근거.
    public let reportGenerating: Bool?
    public let endedAt: Date?

    public init(
        status: InterviewEndedStatus?,
        abandonCause: SessionAbandonCause?,
        ticketOutcome: TicketOutcome?,
        reportGenerating: Bool?,
        endedAt: Date?
    ) {
        self.status = status
        self.abandonCause = abandonCause
        self.ticketOutcome = ticketOutcome
        self.reportGenerating = reportGenerating
        self.endedAt = endedAt
    }
}
