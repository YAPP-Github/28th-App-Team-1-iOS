//
//  HighlightedText.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

// Figma: «highlighted-text» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=1941-7094

import SwiftUI

/// 형광펜 마커 텍스트 — Figma «highlighted-text» 1:1.
///
/// 문장 전체를 넘기고 `hilight(_:)` 로 **강조할 부분만** 지정한다. 지정하지 않으면 전체가 강조된다.
///
/// ```swift
/// HighlightedText("안녕하세요 나는 김은서입니다").hilight("안녕")   // [안녕]하세요 나는 김은서입니다
/// HighlightedText("이름", typography: .head4)                    // 전체 강조
/// ```
///
/// 마커 두께·여백은 `typography` 에서 파생된다 — 크기를 따로 넘기지 않는다.
/// 부분 강조를 하면서 줄바꿈도 되게 하려고 문장을 토큰으로 쪼개 흘려 배치한다(`HighlightFlow`).
/// **강조 구간만은 쪼개지 않는다** — 경사 배경이 조각나면 마커로 안 보이기 때문이다. 그래서 강조 구절이
/// 한 줄을 넘길 만큼 길면 넘친다. 마커는 짧은 구절에 쓰는 게 전제다.
public struct HighlightedText: View {
    /// 색 조합 — Figma `color` 변형 6종. 배경·글자색이 한 쌍이라 따로 고르지 않는다.
    public enum Tone: Sendable, Hashable, CaseIterable {
        case green, black, gray, blue, red, plain

        var foreground: Color {
            switch self {
            case .green: Color.HilitBlack.b800
            case .black: Color.HilitGreen.g500
            case .gray: Color.GrayScale.g500
            case .blue: Color.Positive.p800
            case .red: Color.Error.e500
            case .plain: Color.GrayScale.g900
            }
        }

        var background: Color {
            switch self {
            case .green: Color.HilitGreen.g500
            case .black: Color.HilitBlack.b800
            case .gray: Color.GrayScale.g50
            case .blue: Color.Positive.p200
            case .red: Color.Error.e200
            case .plain: .clear
            }
        }
    }

    /// 마커가 글자를 덮는 방식 — Figma `status` 변형 3종.
    public enum Fill: Sendable {
        /// 글자 높이 전체를 덮는다.
        case full
        /// 글자 가운데를 가로지르는 띠.
        case midlined
        /// 글자 아래에 깔리는 띠.
        case underlined

        var alignment: Alignment {
            switch self {
            case .full, .midlined: .center
            case .underlined: .bottom
            }
        }
    }

    private let text: String
    private let typography: DSTypography
    private let tone: Tone
    private let fill: Fill
    private let icon: Image?
    private let plainForeground: Color
    private let explicitForeground: Color?
    private let explicitBackground: Color?
    private var highlights: [String] = []

    /// - Parameter plainForeground: 강조되지 않은 부분의 글자색. 마커 색은 `tone` 이 정하므로
    ///   이건 화면 배경에 맞춰 따로 준다 (다크 배경이면 흰색 등).
    public init(
        _ text: String,
        typography: DSTypography = .head3,
        tone: Tone = .green,
        fill: Fill = .full,
        icon: Image? = nil,
        plainForeground: Color = Color.GrayScale.g900
    ) {
        self.text = text
        self.typography = typography
        self.tone = tone
        self.fill = fill
        self.icon = icon
        self.plainForeground = plainForeground
        self.explicitForeground = nil
        self.explicitBackground = nil
    }

    /// 팔레트 밖 색 조합을 직접 지정한다 — Figma 변형에 없는 조합일 때만 쓴다.
    public init(
        _ text: String,
        typography: DSTypography = .head3,
        foreground: Color,
        background: Color,
        fill: Fill = .full,
        icon: Image? = nil,
        plainForeground: Color = Color.GrayScale.g900
    ) {
        self.text = text
        self.typography = typography
        self.tone = .green
        self.fill = fill
        self.icon = icon
        self.plainForeground = plainForeground
        self.explicitForeground = foreground
        self.explicitBackground = background
    }

    /// 강조할 부분 문자열을 지정한다. 이어 붙일 수 있고, 나타나는 곳마다 전부 강조된다.
    /// 한 번도 지정하지 않으면 문장 전체가 강조된다.
    public func hilight(_ substring: String) -> HighlightedText {
        var copy = self
        copy.highlights.append(substring)
        return copy
    }

    private var foreground: Color { explicitForeground ?? tone.foreground }
    private var background: Color { explicitBackground ?? tone.background }

    /// 마커 띠 두께 — Figma 는 12~16px 글자에 8pt, 20~24px 글자에 12pt 를 쓴다.
    private var bandHeight: CGFloat { typography.size >= 20 ? 12 : 8 }

    public var body: some View {
        HighlightFlow(lineSpacing: typography.lineHeight - typography.size) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                if segment.isHighlighted {
                    marker(segment.text)
                } else {
                    Text(segment.text)
                        .dsTypography(typography)
                        .foregroundStyle(plainForeground)
                }
            }
        }
    }

    private func marker(_ value: String) -> some View {
        HStack(spacing: 0) {
            if let icon {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    // @ds(spacing): 2 — 아이콘과 글자 사이 (spacing 토큰은 4 부터 시작)
                    .padding(.trailing, 2)
            }
            Text(value)
                .dsTypography(typography)
                .foregroundStyle(foreground)
        }
        .padding(.horizontal, .ds(.p8))
        .background(alignment: fill.alignment) {
            Parallelogram()
                .fill(background)
                .frame(height: fill == .full ? nil : bandHeight)
        }
    }

    // MARK: - 토큰 분할

    private struct Segment {
        let text: String
        let isHighlighted: Bool
    }

    /// 문장을 «강조 / 평문» 으로 쪼갠다. 평문은 줄바꿈이 되도록 어절로 나누고, 공백 없이 긴
    /// 덩어리(한글 문장 등)는 글자 단위까지 나눈다 — 배경이 없어 이어 붙여도 이음매가 안 보인다.
    private var segments: [Segment] {
        guard !highlights.isEmpty else { return [Segment(text: text, isHighlighted: true)] }

        var result: [Segment] = []
        var cursor = text.startIndex
        for range in highlightRanges() {
            if cursor < range.lowerBound {
                result += wrapTokens(String(text[cursor..<range.lowerBound]))
            }
            result.append(Segment(text: String(text[range]), isHighlighted: true))
            cursor = range.upperBound
        }
        if cursor < text.endIndex {
            result += wrapTokens(String(text[cursor...]))
        }
        return result
    }

    /// 강조 구간을 앞에서부터 훑어 겹치지 않게 모은다.
    private func highlightRanges() -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        for needle in highlights where !needle.isEmpty {
            var searchStart = text.startIndex
            while let found = text.range(of: needle, range: searchStart..<text.endIndex) {
                ranges.append(found)
                searchStart = found.upperBound
            }
        }
        var merged: [Range<String.Index>] = []
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound })
        where merged.last.map({ range.lowerBound >= $0.upperBound }) ?? true {
            merged.append(range)
        }
        return merged
    }

    /// 어절 단위(앞 공백 포함)로 쪼개고, 공백 없는 긴 덩어리는 글자 단위로 더 쪼갠다.
    private func wrapTokens(_ value: String) -> [Segment] {
        value.split(separator: " ", omittingEmptySubsequences: false)
            .enumerated()
            .flatMap { index, word -> [String] in
                let piece = index == 0 ? String(word) : " " + word
                return piece.count > 6 ? piece.map(String.init) : [piece]
            }
            .filter { !$0.isEmpty }
            .map { Segment(text: $0, isHighlighted: false) }
    }
}

// MARK: - 흘려 배치

/// 가로로 채우다 넘치면 다음 줄로 내리는 레이아웃. 부분 배경을 그리려면 토큰을 개별 뷰로 둬야 하는데,
/// 기본 스택은 줄바꿈을 못 해서 이걸 쓴다.
private struct HighlightFlow: Layout {
    let lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var total = CGSize.zero
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                total.width = max(total.width, rowWidth)
                total.height += rowHeight + lineSpacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width
            rowHeight = max(rowHeight, size.height)
        }
        total.width = max(total.width, rowWidth)
        total.height += rowHeight
        return total
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("부분 강조") {
    VStack(alignment: .leading, spacing: .ds(.p16)) {
        HighlightedText("안녕하세요 나는 김은서입니다").hilight("안녕")
        HighlightedText("이렇게 전달될 거예요").hilight("이렇게 전달")
        HighlightedText("레포트에 표시될 당신의 이름을 알려주세요", typography: .head4).hilight("이름")
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}

#Preview("색 6종") {
    VStack(alignment: .leading, spacing: .ds(.p12)) {
        ForEach(HighlightedText.Tone.allCases, id: \.self) { tone in
            HighlightedText("텍스트", typography: .body2, tone: tone)
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}

#Preview("마커 방식 3종 · 아이콘") {
    VStack(alignment: .leading, spacing: .ds(.p16)) {
        HighlightedText("텍스트", typography: .body2, fill: .full)
        HighlightedText("텍스트", typography: .body2, fill: .midlined)
        HighlightedText("텍스트", typography: .body2, fill: .underlined)
        HighlightedText("텍스트", typography: .body2, icon: Image.Info.default)
        HighlightedText("텍스트", typography: .head3, tone: .black, fill: .midlined)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
