//
//  HighlightTone.swift
//  DomainInterviewReportInterface
//
//  Created by EunSeo on 26/07/25.
//

import Foundation

/// 서버 `HighlightSpan.tone`(String?) 을 화면이 쓸 수 있게 좁힌 타입.
/// 스웨거 예시가 `"GOOD"` 하나뿐이라 개선 톤 문자열은 아직 미확정 — 미지 값은 `.unknown` 으로 흡수해
/// 강조 없이 평문으로 렌더한다(모르는 값을 개선으로 오인해 빨갛게 칠하지 않는다).
public enum HighlightTone: Equatable, Sendable {
    /// 잘한 문장
    case good
    /// 개선할 문장
    case improve
    /// 서버가 새 값을 내렸거나 nil — 강조하지 않는다
    case unknown

    public init(rawTone: String?) {
        switch rawTone?.uppercased() {
        case "GOOD": self = .good
        case "IMPROVE", "BAD": self = .improve
        default: self = .unknown
        }
    }
}

public extension HighlightSpan {
    /// 타입으로 좁힌 톤.
    var highlightTone: HighlightTone { HighlightTone(rawTone: tone) }
}

public extension InterviewReportCard {
    /// 카드 제목. 축 이름은 내부 용어라 노출하지 않고 순번만 쓴다.
    var displayTitle: String { "질문 \(axisOrder)-\(depthLevel)" }

    /// 해상도 낮음 카드 — 서버가 안내 문구를 내려주면 능력 판단성 분석이 보류된 상태다.
    /// 이 카드는 `highlightSpans` 가 비어 상세 시트로 진입하지 않는다.
    var isLowResolution: Bool { resolutionNotice?.isEmpty == false }

    /// 하이라이트 구간의 문장을 잘라낸다.
    /// `startIndex`/`endIndex` 는 서버가 준 **문자 오프셋**이라 `String.Index` 로 직접 못 쓴다 —
    /// 범위 밖·역순이면 nil 을 돌려 서버 인덱스 불일치가 크래시로 번지는 걸 막는다.
    func sentence(for span: HighlightSpan) -> String? {
        guard let transcript else { return nil }
        let characters = Array(transcript)
        guard span.startIndex >= 0,
              span.endIndex > span.startIndex,
              span.endIndex <= characters.count
        else { return nil }
        return String(characters[span.startIndex..<span.endIndex])
    }

    /// 하이라이트가 영상에서 시작하는 시각(초) — «이 장면 영상으로 보기»의 목적지.
    ///
    /// 서버가 `evidenceStartAt` 을 주면 그대로 쓰고, 없으면 구간 대본에서 문장을 찾아 그 구간 시작으로 대체한다.
    /// 둘 다 없으면 nil — 호출부는 장면 이동 버튼을 숨긴다.
    func evidenceTime(for span: HighlightSpan) -> TimeInterval? {
        if let evidenceStartAt = span.evidenceStartAt { return evidenceStartAt }
        guard let segments, let sentence = sentence(for: span) else { return nil }
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // 하이라이트가 구간 경계와 딱 맞지 않을 수 있어 포함 관계를 양방향으로 본다.
        return segments.first { $0.text.contains(trimmed) || trimmed.contains($0.text) }?.start
    }

    /// 재생 순서대로 정렬된 구간. 서버 정렬을 신뢰하지 않고 시작 시각으로 다시 세운다 —
    /// 진행바 칸 순서가 뒤집히면 이동 지점이 어긋난다.
    var orderedSegments: [TranscriptSegment] {
        (segments ?? []).sorted { $0.start < $1.start }
    }
}
