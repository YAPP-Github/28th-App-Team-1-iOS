//
//  InterviewQuestion.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

/// 질문의 턴 위치 — turnLevel 0 = 요약 질문(첫 턴), depthLevel = 꼬리질문 깊이.
public struct TurnInfo: Decodable, Equatable, Sendable {
    public let turnLevel: Int
    public let depthLevel: Int

    public init(turnLevel: Int, depthLevel: Int) {
        self.turnLevel = turnLevel
        self.depthLevel = depthLevel
    }
}

/// 세션 READY 시 동봉되는 요약 질문(turnLevel=0). `ttsAudio` 는 base64 mp3 — 이후 질문은 스트리밍으로 받는다.
public struct SummaryQuestion: Decodable, Equatable, Sendable {
    public let questionId: Int
    public let ttsAudio: String?
    public let turn: TurnInfo?

    public init(questionId: Int, ttsAudio: String?, turn: TurnInfo?) {
        self.questionId = questionId
        self.ttsAudio = ttsAudio
        self.turn = turn
    }

    /// base64 디코드된 mp3 데이터
    public var audioData: Data? {
        ttsAudio.flatMap { Data(base64Encoded: $0) }
    }
}

/// 답변 제출 응답의 다음 질문 메타데이터. 오디오는 동봉되지 않는다 — `questionAudioStream` 으로 별도 스트리밍.
public struct NextQuestion: Decodable, Equatable, Sendable {
    public let questionId: Int
    public let isLast: Bool?
    public let turn: TurnInfo?

    public init(questionId: Int, isLast: Bool?, turn: TurnInfo?) {
        self.questionId = questionId
        self.isLast = isLast
        self.turn = turn
    }
}

/// 질문 TTS 점진 재생(progressive playback) 정보 — `AVURLAsset(url:options:[헤더])` → `AVPlayer`.
/// 응답은 `Transfer-Encoding: chunked` (Content-Length 없음) — 전부 받고 재생하지 말 것.
/// 중간 실패는 HTTP 코드로 안 잡힌다 — 재생 에러 콜백으로 감지하고 같은 questionId 로 재호출(TTS 재생성).
public struct InterviewAudioStream: Equatable, Sendable {
    public let url: URL
    /// Authorization 헤더 (Bearer Access Token)
    public let headers: [String: String]

    public init(url: URL, headers: [String: String]) {
        self.url = url
        self.headers = headers
    }
}
