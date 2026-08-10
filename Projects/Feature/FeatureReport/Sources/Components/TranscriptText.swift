//
//  TranscriptText.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

/// 답변 대본 + 하이라이트 구간. 구간은 본문 흐름 안에서 색과 밴드로 강조되고, 눌리면 상세 시트로 간다.
///
/// 한 문단 안의 일부 범위만 탭 대상으로 만들어야 해서 `AttributedString` 의 `link` 속성을 태그로 쓰고
/// `openURL` 로 가로챈다 — SwiftUI 에는 텍스트 하위 범위에 제스처를 붙이는 API 가 없다.
/// 링크 URL 은 화면 밖으로 나가지 않는 내부 스킴이라 실제로 열리지 않는다.
///
/// **밴드는 글자와 다른 층에 그린다** — 같은 `Text` 안에서 `backgroundColor` 와 `link` 가 겹치면
/// 밴드가 글자에 붙지 않고 줄 높이만 한 네모로 커진다(탭이 없는 상세 시트만 글자에 붙어 두 화면이 달랐다).
/// 그래서 글자를 지운 같은 문장을 뒤에 깔아 밴드만 그리고, 앞 층은 색과 링크만 갖는다 —
/// 두 층은 문자열·폰트·폭이 같아 줄바꿈이 같으므로 밴드가 글자 자리에 정확히 앉는다.
struct TranscriptText: View {
    /// 하이라이트 구간 탭을 식별하는 내부 스킴 — 외부에 노출되지 않는다.
    private static let scheme = "hilit-span"

    let transcript: String
    let spans: [HighlightSpan]
    /// 하이라이트가 아닌 본문 색 — 메인은 gray50, 시트는 gray600(하이라이트를 도드라지게).
    let baseColor: Color
    /// 하이라이트 구간 밴드 색 — 판이 다르면 밴드도 한 단 움직인다
    /// (리포트 카드 g800 / 플레이어 대본 오버레이 g900 — 시안 443:7301 vs 443:7906).
    let bandColor: Color
    /// 잘함 톤 글자색 — 카드·시트는 `p500`, 플레이어 오버레이만 `p800`(«근사 판단» 아래 참조).
    let goodToneColor: Color
    /// 하이라이트 구간 탭 (구간 인덱스). nil 이면 탭 비활성 — 시트 안처럼 이미 그 구간을 보고 있을 때.
    let onTapSpan: ((Int) -> Void)?

    init(
        transcript: String,
        spans: [HighlightSpan],
        baseColor: Color = Color.GrayScale.g50,
        bandColor: Color = Color.GrayScale.g800,
        goodToneColor: Color = Color.Positive.p500,
        onTapSpan: ((Int) -> Void)? = nil
    ) {
        self.transcript = transcript
        self.spans = spans
        self.baseColor = baseColor
        self.bandColor = bandColor
        self.goodToneColor = goodToneColor
        self.onTapSpan = onTapSpan
    }

    var body: some View {
        line(attributed(layer: .text))
            .background { band }
            .environment(\.openURL, OpenURLAction { url in
                guard let index = Self.spanIndex(from: url) else { return .discarded }
                onTapSpan?(index)
                return .handled
            })
    }

    /// 밴드 층 — 글자는 투명하고 배경만 남는다. 링크가 없어야 밴드가 글자에 붙는다.
    private var band: some View {
        line(attributed(layer: .band))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// 두 층이 같은 자리에 겹치려면 글꼴·줄바꿈 규칙이 한 글자도 어긋나면 안 된다 — 한 곳에서만 정한다.
    private func line(_ value: AttributedString) -> some View {
        Text(value)
            .dsTypography(.body3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Layer {
        /// 글자 색 + 구간 탭.
        case text
        /// 하이라이트 구간 밴드.
        case band
    }

    private func attributed(layer: Layer) -> AttributedString {
        var result = AttributedString(transcript)
        result.foregroundColor = layer == .band ? .clear : baseColor

        let characterCount = transcript.count
        for (index, span) in spans.enumerated() {
            // 서버 인덱스가 대본과 어긋나면 그 구간만 조용히 건너뛴다 — 크래시로 번지지 않게.
            guard span.startIndex >= 0,
                  span.endIndex > span.startIndex,
                  span.endIndex <= characterCount,
                  let range = range(in: result, from: span.startIndex, to: span.endIndex)
            else { continue }

            switch layer {
            case .text:
                result[range].foregroundColor = color(for: span.highlightTone)
                if onTapSpan != nil {
                    result[range].link = URL(string: "\(Self.scheme):\(index)")
                }
            case .band:
                result[range].backgroundColor = bandColor
            }
        }
        return result
    }

    private func range(
        in string: AttributedString,
        from start: Int,
        to end: Int
    ) -> Range<AttributedString.Index>? {
        let lower = string.index(string.startIndex, offsetByCharacters: start)
        let upper = string.index(string.startIndex, offsetByCharacters: end)
        return lower < upper ? lower..<upper : nil
    }

    private static func spanIndex(from url: URL) -> Int? {
        guard url.scheme == scheme else { return nil }
        return Int(url.absoluteString.dropFirst(scheme.count + 1))
    }

    /// 미지 톤은 강조하지 않는다 — 모르는 값을 개선으로 오인해 빨갛게 칠하지 않기 위해서.
    /// 본문 색을 그대로 물려받아야 «강조 없음» 이 된다(플레이어 오버레이는 줄마다 본문 색이 다르다).
    ///
    /// 잘함은 기본 `p500`(2026-08-05 확정) — 단 **플레이어 오버레이는 `p800`** 이다: 새 대본 시안
    /// 443:7919(#008A9F)에 톤 글자색이 확인돼(2026-08-07) 그 판만 `goodToneColor` 로 갈아끼운다.
    private func color(for tone: HighlightTone) -> Color {
        switch tone {
        case .good: goodToneColor
        case .improve: Color.Error.e400
        case .unknown: baseColor
        }
    }
}

#Preview("대본 하이라이트") {
    VStack(alignment: .leading, spacing: 24) {
        TranscriptText(
            transcript: "프로파일링하니 DB 왕복 7번이 원인이라, 안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요.",
            spans: [HighlightSpan(startIndex: 8, endIndex: 45, tone: "GOOD", analysis: nil)],
            onTapSpan: { _ in }
        )
        TranscriptText(
            transcript: "대학교에서는 시각디자인을 전공하며, 음 디자인 동아리 활동과 여러 공모전에 도전했습니다.",
            spans: [HighlightSpan(startIndex: 20, endIndex: 44, tone: "IMPROVE", analysis: nil)],
            baseColor: Color.GrayScale.g600,
            onTapSpan: { _ in }
        )
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
