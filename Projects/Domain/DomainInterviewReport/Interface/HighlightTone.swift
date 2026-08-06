//
//  HighlightTone.swift
//  DomainInterviewReportInterface
//
//  Created by EunSeo on 26/07/25.
//

import Foundation

/// 서버 `HighlightSpan.tone`(String?) 을 화면이 쓸 수 있게 좁힌 타입.
/// 미지 값은 `.unknown` 으로 흡수해 강조 없이 평문으로 렌더한다
/// (모르는 값을 개선으로 오인해 빨갛게 칠하지 않는다).
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

/// 서버 `HighlightSpan.reason`(String?) — 하이라이트가 뽑힌 이유.
/// 시트의 «다음 대비» 판을 가른다: 파고들 여지면 꼬리질문, 딴 답이면 의도 대조.
/// 미지 값은 `.unknown` — 둘 다 그리지 않는다(모르는 이유로 판을 고르지 않는다).
public enum HighlightReason: Equatable, Sendable {
    /// 파고들 여지 — `followUpQuestions` 가 채워진다.
    case probeWorthy
    /// 질문과 다른 답 — `answerTopicTitle`·`questionIntentTitle`·`questionIntent` 가 채워진다.
    case offIntent
    /// 짧고 얕음
    case shallow
    /// 충분함
    case sufficient
    /// 서버가 새 값을 내렸거나 nil
    case unknown

    public init(rawReason: String?) {
        switch rawReason?.uppercased() {
        case "PROBE_WORTHY": self = .probeWorthy
        case "OFF_INTENT": self = .offIntent
        case "SHALLOW": self = .shallow
        case "SUFFICIENT": self = .sufficient
        default: self = .unknown
        }
    }
}

public extension HighlightSpan {
    /// 타입으로 좁힌 톤.
    var highlightTone: HighlightTone { HighlightTone(rawTone: tone) }

    /// 타입으로 좁힌 이유.
    var highlightReason: HighlightReason { HighlightReason(rawReason: reason) }
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
    /// 서버가 `startSec` 을 주면 그대로 쓰고, 없으면 이 턴의 발화에서 하이라이트가 걸친
    /// 첫 문장을 문자 오프셋으로 찾아 그 시작으로 대체한다. 둘 다 없으면 nil —
    /// 호출부는 영상을 처음부터 재생한다.
    func evidenceTime(for span: HighlightSpan) -> TimeInterval? {
        if let startSec = span.startSec { return startSec }
        // 하이라이트와 발화가 같은 좌표계(카드 `transcript` 오프셋)라 겹침으로 찾는다.
        return orderedSegments.first {
            guard let start = $0.startIndex, let end = $0.endIndex else { return false }
            return start < span.endIndex && span.startIndex < end
        }?.startSec
    }

    /// 재생 순서대로 정렬된 **면접자 발화**. 면접관 질문은 카드 대본(`transcript`)에 없어
    /// 하이라이트·오버레이 문장에 못 쓴다. 서버 정렬을 신뢰하지 않고 시작 시각으로 다시 세운다 —
    /// 문장 순서가 뒤집히면 오버레이 누적·이동 지점이 어긋난다.
    var orderedSegments: [ScriptSegment] {
        (scriptSegments ?? [])
            .filter { $0.role == .interviewee }
            .sorted { $0.startSec < $1.startSec }
    }
}
