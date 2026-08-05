//
//  VideoTranscript.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import Foundation

/// 플레이어가 쓰는 대본 타임라인. 카드별 답변을 **시간축 하나**로 펼친 파생값이다.
///
/// 두 가지를 만든다 — 진행바의 칸(`chunks`)과 오버레이 대본 줄(`lines`, 카드 1:1).
/// 칸은 세션 전체 타임라인(`script` — 면접관 멘트 포함)에서 세운다: 시안의 하단 덩어리는
/// 답변만이 아니라 영상 전체를 나눈다. `script` 가 없으면 카드의 면접자 발화로,
/// 그마저 없으면 플레이어가 전체 길이 한 칸으로 대체한다.
struct VideoTranscript: Equatable {

    /// 진행바 칸 = 이동 단위. 폭은 길이에 비례하고, 탭하면 `start` 로 이동한다.
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

    /// 오버레이 대본 한 덩어리 = 카드(질문 턴) 하나의 답변.
    /// 하이라이트 구간은 서버 배열 그대로 넘긴다 — 색·밴드·부분 탭은 `TranscriptText` 규약을 따른다.
    struct Line: Equatable, Identifiable {
        /// 카드 인덱스 — 하이라이트 탭을 리듀서에 돌려줄 때 쓴다.
        let id: Int
        let text: String
        let spans: [HighlightSpan]
        /// 이 답변의 구간이 걸쳐 있는 시간대. 구간이 없으면 nil — «현재 줄» 판정에서 빠진다.
        let start: TimeInterval?
        let end: TimeInterval?

        func contains(_ time: TimeInterval) -> Bool {
            guard let start, let end else { return false }
            return time >= start && time < end
        }
    }

    let lines: [Line]
    let chunks: [Chunk]

    init(cards: [InterviewReportCard], script: [ScriptSegment] = []) {
        lines = cards.enumerated().compactMap { index, card in
            guard let text = card.transcript, !text.isEmpty else { return nil }
            let segments = card.orderedSegments
            return Line(
                id: index,
                text: text,
                spans: card.highlightSpans ?? [],
                start: segments.first?.startSec,
                end: segments.last?.endSec
            )
        }
        // 전체 타임라인이 있으면 그대로 칸이 된다(인사·질문·마무리 포함). 없으면
        // 카드 경계를 넘겨 면접자 발화를 한 줄로 세운다 — 어느 쪽이든 영상 시간축을 보여준다.
        let source = script.isEmpty ? cards.flatMap(\.orderedSegments) : script
        chunks = source
            .sorted { $0.startSec < $1.startSec }
            .enumerated()
            .map { Chunk(id: $0.offset, start: $0.element.startSec, end: $0.element.endSec) }
    }

    /// 지금 재생 중인 줄. 구간 정보가 없으면 nil — 오버레이는 전부 같은 색으로 둔다.
    func currentLineID(at time: TimeInterval) -> Line.ID? {
        lines.first { $0.contains(time) }?.id
    }
}
