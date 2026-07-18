//
//  InterviewAnswer.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

/// 종료·특수 처리 사유. nil = 정상 답변 제출. (타이머 상태머신 → docs/work/ai-interview.md §6)
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
    /// 면접 시작 8:45 경과 여부 (클라이언트 타이머 기준)
    public var isWrapUp: Bool?

    public init(
        questionId: Int,
        audio: Data? = nil,
        questionAudioStartAt: Double? = nil,
        questionAudioEndAt: Double? = nil,
        answerStartAt: Double? = nil,
        answerEndAt: Double? = nil,
        answerDuration: Double? = nil,
        endType: AnswerEndType? = nil,
        isWrapUp: Bool? = nil
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

/// 답변 제출 응답 — 다음 질문 또는(면접 종료 시) `reportId`.
public struct AnswerResult: Decodable, Equatable, Sendable {
    public let answerId: Int?
    public let nextQuestion: NextQuestion?
    public let wrapUpMessage: String?
    public let reportId: Int?

    public init(answerId: Int?, nextQuestion: NextQuestion?, wrapUpMessage: String?, reportId: Int?) {
        self.answerId = answerId
        self.nextQuestion = nextQuestion
        self.wrapUpMessage = wrapUpMessage
        self.reportId = reportId
    }
}
