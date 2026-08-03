//
//  InterviewAnswer.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

/// 종료·특수 처리 사유(요청). nil = 정상 답변 제출. 응답의 `SessionEndType` 과 값 집합이 달라
/// 분리 유지한다. (타이머 상태머신 → docs/work/ai-interview.md §6)
public enum AnswerEndType: String, Equatable, Sendable {
    /// 답변 건너뜀 (audio 없음)
    case skip = "SKIP"
    /// 8:00 경과 후 사용자가 종료 버튼으로 수동 종료
    case manualEnd = "MANUAL_END"
    /// 12:00 경과로 서버 강제 종료
    case hardCap = "HARD_CAP"
    /// 0:00~8:00 사이 의도적 이탈 (차감 경고 확인 후)
    case earlyExit = "EARLY_EXIT"
}

/// POST /interview/sessions/{id}/answers 입력. 시간값은 영상 녹화 기준 초 단위.
public struct AnswerSubmission: Equatable, Sendable {
    public var questionId: Int
    /// 답변 음성(mp3). `endType == .skip` 이면 nil 허용.
    public var audio: Data?
    /// AI 질문 TTS 재생 시작/종료 시간
    public var questionAudioStartAt: Double?
    public var questionAudioEndAt: Double?
    /// 답변 시작/종료 시간·길이
    public var answerStartAt: Double?
    public var answerEndAt: Double?
    public var answerDuration: Double?
    public var endType: AnswerEndType?
    /// 면접 시작 8:45 경과 여부 (클라이언트 타이머 기준) — 스펙 required, nil 전송 경로 없음.
    public var isWrapUp: Bool

    public init(
        questionId: Int,
        audio: Data? = nil,
        questionAudioStartAt: Double? = nil,
        questionAudioEndAt: Double? = nil,
        answerStartAt: Double? = nil,
        answerEndAt: Double? = nil,
        answerDuration: Double? = nil,
        endType: AnswerEndType? = nil,
        isWrapUp: Bool
    ) {
        self.questionId = questionId
        self.audio = audio
        self.questionAudioStartAt = questionAudioStartAt
        self.questionAudioEndAt = questionAudioEndAt
        self.answerStartAt = answerStartAt
        self.answerEndAt = answerEndAt
        self.answerDuration = answerDuration
        self.endType = endType
        self.isWrapUp = isWrapUp
    }
}

/// 세션 종료 사유(응답) — 서버가 판정해 내려준다. 요청용 `AnswerEndType`(SKIP 포함)과 값 집합이 다르다.
public enum SessionEndType: String, Decodable, Equatable, Sendable {
    /// 마무리 질문까지 답변한 자연 종료.
    case normalEnd = "NORMAL_END"
    /// 8:00 경과 후 사용자가 «마치기» 로 종료.
    case manualEnd = "MANUAL_END"
    /// 12:00 상한 도달 강제 종료.
    case hardCap = "HARD_CAP"
    /// 8:00 전 의도적 이탈 — 리포트 없이 종료.
    case earlyExit = "EARLY_EXIT"
    /// STT 30% 실패 판정(서버) — 이용권 환불·리포트 없음. 세션은 무효화된다.
    case sttReset = "STT_RESET"
}

/// 마무리 멘트 — base64 mp3. 재생은 fire-and-forget(리포트 대기 전환을 멈춰 세우지 않는다, PRD §3.7).
public struct WrapUpMessage: Decodable, Equatable, Sendable {
    public let ttsAudio: String?

    public init(ttsAudio: String?) {
        self.ttsAudio = ttsAudio
    }

    /// base64 디코드된 mp3 데이터
    public var audioData: Data? {
        ttsAudio.flatMap { Data(base64Encoded: $0) }
    }
}

/// 답변 제출 응답 — 다음 질문 또는 세션 종료(`endType` 5종). `reportId` 는 스펙에서 삭제됐다.
public struct AnswerResult: Decodable, Equatable, Sendable {
    public let answerId: Int?
    public let nextQuestion: NextQuestion?
    public let sessionEnded: Bool
    public let wrapUpMessage: WrapUpMessage?
    public let endType: SessionEndType?

    public init(
        answerId: Int?,
        nextQuestion: NextQuestion?,
        sessionEnded: Bool,
        wrapUpMessage: WrapUpMessage?,
        endType: SessionEndType?
    ) {
        self.answerId = answerId
        self.nextQuestion = nextQuestion
        self.sessionEnded = sessionEnded
        self.wrapUpMessage = wrapUpMessage
        self.endType = endType
    }
}
