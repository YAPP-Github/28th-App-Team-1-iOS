//
//  VideoTranscript.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import Foundation

/// 플레이어가 쓰는 대본 타임라인. 카드(질문 턴)를 **시간축 하나**로 펼친 파생값이다.
///
/// 두 가지를 만든다 — 진행바의 칸(`chunks`)과 오버레이 대본 줄(`lines`), 둘 다 카드 1:1.
/// **덩어리 = 질문 턴**이다(2026-08-07 확정 — 발화 하나당 칸 하나는 너무 잘게 쪼개져 폐기).
/// 오버레이는 턴 안에서 문장(발화) 단위로 재생 시각까지 쌓는다 — `position(at:)` 이
/// «어느 턴의 몇 번째 문장까지 왔는가» 를 답하고, 화면은 그 앞 문장들만 그린다.
struct VideoTranscript: Equatable {

    /// 진행바 칸 = 질문 턴 = 이동 단위. 폭은 길이에 비례하고, 탭하면 `start` 로 이동한다.
    /// `id` 는 카드 인덱스 — 대본 줄과 같은 좌표계라 칸을 누르면 그 턴 대본으로 이어진다.
    struct Chunk: Equatable, Identifiable {
        let id: Int
        let start: TimeInterval
        let end: TimeInterval

        var duration: TimeInterval { max(0, end - start) }

        /// 이 칸이 얼마나 재생됐는지 (0...1).
        func fillRatio(at time: TimeInterval) -> Double {
            guard duration > 0 else { return time >= start ? 1 : 0 }
            return min(1, max(0, (time - start) / duration))
        }
    }

    /// 오버레이 대본 문장 하나 = 그 턴의 면접자 발화(`ScriptSegment`) 하나.
    /// 하이라이트 구간은 카드 좌표계에서 이 문장 범위로 잘라 **문장-로컬 오프셋**으로 옮겨 담는다 —
    /// `TranscriptText` 는 받은 문자열 기준 인덱스만 안다.
    struct Sentence: Equatable, Identifiable {
        /// 카드 안 순번.
        let id: Int
        let text: String
        let spans: [HighlightSpan]
        /// `spans[i]` 가 카드 원본 `highlightSpans` 의 몇 번째인지 — 탭을 리듀서에 돌려줄 때 쓴다.
        let spanIndices: [Int]
        /// 발화 시작 시각 — 이 시각부터 문장이 오버레이에 나타난다.
        let start: TimeInterval
    }

    /// 오버레이 대본 한 덩어리 = 카드(질문 턴) 하나의 답변, 문장 단위로 쪼개 담는다.
    struct Line: Equatable, Identifiable {
        /// 카드 인덱스 — 하이라이트 탭을 리듀서에 돌려줄 때 쓴다.
        let id: Int
        let sentences: [Sentence]
    }

    /// 오버레이가 보여줄 위치 — 어느 턴(`lineID`)의 몇 번째 문장(`sentenceIndex`)까지 왔는가.
    struct Position: Equatable {
        let lineID: Int
        let sentenceIndex: Int
    }

    /// 문장 시작 시각 → 위치 매핑 한 줄. `position(at:)` 의 재료라 시각 오름차순으로 세운다.
    private struct Cue: Equatable {
        let start: TimeInterval
        let position: Position
    }

    let lines: [Line]
    let chunks: [Chunk]
    private let cues: [Cue]

    init(cards: [InterviewReportCard]) {
        var lines: [Line] = []
        var chunks: [Chunk] = []
        var cues: [Cue] = []
        for (index, card) in cards.enumerated() {
            // 칸은 턴 발화 전체(면접관 질문 포함)를 덮는다 — 탭하면 질문부터 듣는다.
            let turnSegments = (card.scriptSegments ?? []).sorted { $0.startSec < $1.startSec }
            if let first = turnSegments.first, let last = turnSegments.last {
                chunks.append(Chunk(id: index, start: first.startSec, end: last.endSec))
            }
            let sentences = Self.sentences(of: card)
            guard !sentences.isEmpty else { continue }
            lines.append(Line(id: index, sentences: sentences))
            for sentence in sentences {
                cues.append(Cue(
                    start: sentence.start,
                    position: Position(lineID: index, sentenceIndex: sentence.id)
                ))
            }
        }
        self.lines = lines
        self.chunks = chunks
        self.cues = cues.sorted { $0.start < $1.start }
    }

    /// 이 시각까지 온 위치 — 시작이 지난 문장 중 마지막. 첫 발화 전이면 nil(오버레이는 스크림만).
    /// 턴 사이 공백(면접관 발화)에는 직전 턴 위치가 그대로 남는다 — 대본이 비었다 차는 깜빡임을 막는다.
    func position(at time: TimeInterval) -> Position? {
        cues.last { $0.start <= time }?.position
    }

    func line(with id: Line.ID) -> Line? {
        lines.first { $0.id == id }
    }

    /// 카드의 면접자 발화를 문장으로 편다. 문자 오프셋(`startIndex`/`endIndex`)이 대본과 어긋나면
    /// 그 문장은 발화 원문으로만 물러난다 — 하이라이트 좌표계를 잃어 구간 없이 그린다(크래시 금지).
    private static func sentences(of card: InterviewReportCard) -> [Sentence] {
        guard let transcript = card.transcript, !transcript.isEmpty else { return [] }
        let characters = Array(transcript)
        let spans = card.highlightSpans ?? []
        return card.orderedSegments.enumerated().map { offset, segment in
            guard let start = segment.startIndex, let end = segment.endIndex,
                  start >= 0, end > start, end <= characters.count
            else {
                return Sentence(id: offset, text: segment.text, spans: [], spanIndices: [], start: segment.startSec)
            }
            var localSpans: [HighlightSpan] = []
            var spanIndices: [Int] = []
            for (spanIndex, span) in spans.enumerated() {
                let lower = max(span.startIndex, start)
                let upper = min(span.endIndex, end)
                guard lower < upper else { continue }
                localSpans.append(span.moved(startIndex: lower - start, endIndex: upper - start))
                spanIndices.append(spanIndex)
            }
            return Sentence(
                id: offset,
                text: String(characters[start..<end]),
                spans: localSpans,
                spanIndices: spanIndices,
                start: segment.startSec
            )
        }
    }
}

private extension HighlightSpan {
    /// 문장-로컬 좌표계로 옮긴 사본 — 인덱스만 바뀌고 내용은 그대로다.
    func moved(startIndex: Int, endIndex: Int) -> HighlightSpan {
        HighlightSpan(
            startIndex: startIndex,
            endIndex: endIndex,
            tone: tone,
            reason: reason,
            title: title,
            analysis: analysis,
            followUpQuestions: followUpQuestions,
            startSec: startSec,
            answerTopicTitle: answerTopicTitle,
            questionIntentTitle: questionIntentTitle,
            questionIntent: questionIntent
        )
    }
}
