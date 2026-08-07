//
//  InterviewResume.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/08/08.
//

import Foundation

/// 재개 판정. RESUMABLE = 세션 IN_PROGRESS + 이용권 예약 HELD + heldAt 20분 이내 (서버 판정).
public enum InterviewResumeState: String, Decodable, Equatable, Sendable {
    case resumable = "RESUMABLE"
    case ended = "ENDED"
}

/// GET /interview/sessions/{id}/resume 응답 — 순수 조회다(재개 확정은 같은 경로 POST).
/// 단 hold 만료가 원인인 ENDED 는 서버가 이 호출 안에서 세션 ABANDONED 전환 + 이용권 환불까지
/// 마치고 내려준다 — 클라가 뒤이어 할 처리는 없다.
public struct InterviewResumeCheck: Decodable, Equatable, Sendable {
    public let resumeState: InterviewResumeState
    /// RESUMABLE 일 때만 — 세션 시작 시각(LocalDateTime, KST 가정 — [[api#Interview]] 날짜 규약).
    public let startedAt: Date?
    /// RESUMABLE 일 때만 — 시작 후 경과 초. 남은 시간·질문 수 표기의 서버측 근거.
    public let elapsedSeconds: Int?
    /// ENDED 일 때만 — 어떻게 끝난 세션인지.
    public let status: InterviewEndedStatus?

    public init(
        resumeState: InterviewResumeState,
        startedAt: Date?,
        elapsedSeconds: Int?,
        status: InterviewEndedStatus?
    ) {
        self.resumeState = resumeState
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.status = status
    }

    /// 화면 분기는 이 한 줄로 충분하다 — 부속 필드 유무로 판정하지 말 것.
    public var isResumable: Bool { resumeState == .resumable }
}
