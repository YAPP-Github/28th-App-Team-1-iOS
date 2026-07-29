//
//  TranscriptTimestamp.swift
//  DomainInterviewReportInterface
//
//  Created by EunSeo on 26/07/29.
//

import Foundation

/// STT 대본의 시간축. 서버는 같은 답변을 **두 해상도**로 내려준다 —
/// 구간(`TranscriptSegment`)과 단어(`TranscriptWord`).
///
/// 화면은 구간만 쓴다: 플레이어 진행바의 칸 하나 = 구간 하나이고, 칸을 누르면 그 구간 시작으로 이동한다.
/// 단어는 계약만 열어 둔다 — 노래방식 단어 강조가 필요해질 때 화면 코드만 붙이면 되게.

/// 대본 구간(문장 단위) 하나. `start`/`end` 는 영상 시작 기준 초.
public struct TranscriptSegment: Decodable, Equatable, Sendable {
    public let text: String
    public let start: TimeInterval
    public let end: TimeInterval

    public init(text: String, start: TimeInterval, end: TimeInterval) {
        self.text = text
        self.start = start
        self.end = end
    }

    /// 구간 길이. 서버가 뒤집힌 값을 줘도 진행바 폭이 음수가 되지 않게 0 으로 막는다.
    public var duration: TimeInterval { max(0, end - start) }

    /// 이 구간이 재생 중인지. 끝 시각은 다음 구간의 시작이라 배타로 본다.
    public func contains(_ time: TimeInterval) -> Bool {
        time >= start && time < end
    }
}

/// 단어 하나의 시각 — 현재 UI 미사용(계약 보존용).
public struct TranscriptWord: Decodable, Equatable, Sendable {
    public let word: String
    public let start: TimeInterval
    public let end: TimeInterval

    public init(word: String, start: TimeInterval, end: TimeInterval) {
        self.word = word
        self.start = start
        self.end = end
    }
}
