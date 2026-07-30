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
/// 문장 전체를 넘기고 체인으로 마커를 얹는다. 강조 부분을 지정하지 않으면 문장 전체가 강조된다.
///
/// ```swift
/// HighlightedText("안녕하세요 나는 김은서입니다")
///     .hilight("안녕")            // [안녕]하세요 나는 김은서입니다
///     .hilightColor(.green)      // 글자색·배경색이 한 쌍으로 정해진다
///     .hilightFill(.midlined)
///
/// HighlightedText("이름", typography: .head4)   // 체인 없으면 전체 강조
/// ```
///
/// `Text` 에 붙이는 형태(`Text("…").hilight("안녕")`)는 만들 수 없다 — SwiftUI `Text` 는 담고 있는
/// 문자열을 다시 꺼낼 수 없어서 어느 문장에서 부분을 찾을지 알 방법이 없다. 그래서 진입점만 타입이다.
///
/// 마커 두께·여백은 `typography` 에서 파생된다 — 크기를 따로 넘기지 않는다.
/// 부분 강조를 하면서 줄바꿈도 되게 하려고 문장을 토큰으로 쪼개 흘려 배치한다(`HighlightFlow`).
/// **강조 구간만은 쪼개지 않는다** — 경사 배경이 조각나면 마커로 안 보이기 때문이다. 그래서 강조 구절이
/// 한 줄을 넘길 만큼 길면 넘친다. 마커는 짧은 구절에 쓰는 게 전제다.
public struct HighlightedText: View {
    /// 색 조합 — Figma `color` 변형 6종. **글자색과 배경색이 한 쌍**이라 따로 고르지 않는다.
    public enum Tone: Sendable, Hashable, CaseIterable {
        case green, black, gray, blue, red, none

        var foreground: Color {
            switch self {
            case .green: Color.HilitBlack.b800
            case .black: Color.HilitGreen.g500
            case .gray: Color.GrayScale.g500
            case .blue: Color.Positive.p800
            case .red: Color.Error.e500
            case .none: Color.GrayScale.g900
            }
        }

        var background: Color {
            switch self {
            case .green: Color.HilitGreen.g500
            case .black: Color.HilitBlack.b800
            case .gray: Color.GrayScale.g50
            case .blue: Color.Positive.p200
            case .red: Color.Error.e200
            case .none: .clear
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
    private let alignment: TextAlignment
    private let plainForeground: Color
    private var tone: Tone = .green
    private var fill: Fill = .full
    private var icon: Image?
    private var explicitForeground: Color?
    private var explicitBackground: Color?
    private var highlights: [String] = []

    /// 마커 스타일은 전부 `hilight…` 체인으로 얹는다 — 여기엔 텍스트 자체의 속성만 둔다.
    ///
    /// - Parameters:
    ///   - alignment: 줄이 넘칠 때 각 줄을 어느 쪽에 붙일지. 가운데·오른쪽 정렬은 흘려 배치가 부모 폭을
    ///     채워야 성립하므로, 호출부가 `.frame(maxWidth:)` 등으로 폭을 줘야 눈에 보인다.
    ///   - plainForeground: 강조되지 않은 부분의 글자색. 마커 색은 `hilightColor(_:)` 가
    ///     정하므로 이건 화면 배경에 맞춰 따로 준다 (다크 배경이면 흰색 등).
    public init(
        _ text: String,
        typography: DSTypography = .head3,
        alignment: TextAlignment = .leading,
        plainForeground: Color = Color.GrayScale.g900
    ) {
        self.text = text
        self.typography = typography
        self.alignment = alignment
        self.plainForeground = plainForeground
    }

    // MARK: - 체인

    /// 강조할 부분 문자열. 이어 붙일 수 있고, 나타나는 곳마다 전부 강조된다.
    /// 한 번도 지정하지 않으면 문장 전체가 강조된다.
    public func hilight(_ substring: String) -> Self {
        var copy = self
        copy.highlights.append(substring)
        return copy
    }

    /// 마커 색 — 글자색과 배경색이 한 쌍으로 정해진다 (Figma `color` 변형 6종).
    public func hilightColor(_ tone: Tone) -> Self {
        var copy = self
        copy.tone = tone
        copy.explicitForeground = nil
        copy.explicitBackground = nil
        return copy
    }

    /// 팔레트 밖 색 조합 — Figma 변형에 없는 조합일 때만 쓴다.
    public func hilightColors(foreground: Color, background: Color) -> Self {
        var copy = self
        copy.explicitForeground = foreground
        copy.explicitBackground = background
        return copy
    }

    /// 마커가 글자를 덮는 방식 (Figma `status` 변형 3종).
    public func hilightFill(_ fill: Fill) -> Self {
        var copy = self
        copy.fill = fill
        return copy
    }

    /// 마커 안 글자 앞에 붙는 아이콘.
    public func hilightIcon(_ image: Image?) -> Self {
        var copy = self
        copy.icon = image
        return copy
    }

    private var foreground: Color { explicitForeground ?? tone.foreground }
    private var background: Color { explicitBackground ?? tone.background }

    /// 마커 띠 두께 — Figma 는 12~16px 글자에 8pt, 20~24px 글자에 12pt 를 쓴다.
    private var bandHeight: CGFloat { typography.size >= 20 ? 12 : 8 }

    public var body: some View {
        HighlightFlow(lineSpacing: typography.lineHeight - typography.size, alignment: alignment) {
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
///
/// 줄을 먼저 다 묶은 뒤에 배치한다 — 한 줄을 오른쪽으로 밀어 정렬하려면 그 줄의 총 폭을 미리 알아야 한다.
private struct HighlightFlow: Layout {
    let lineSpacing: CGFloat
    let alignment: TextAlignment

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let rows = rows(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        let contentWidth = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        // 가운데·오른쪽 정렬은 부모 폭을 채워야 «줄마다» 밀 수 있다. 왼쪽 정렬은 내용 폭을 그대로 hug.
        guard alignment != .leading, let proposed = proposal.width, proposed.isFinite else {
            return CGSize(width: contentWidth, height: height)
        }
        return CGSize(width: max(contentWidth, proposed), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var originY = bounds.minY
        for row in rows(subviews: subviews, maxWidth: bounds.width) {
            var originX = bounds.minX + (bounds.width - row.width) * offsetFactor
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: originX, y: originY), proposal: ProposedViewSize(size))
                originX += size.width
            }
            originY += row.height + lineSpacing
        }
    }

    /// 넘치는 지점마다 끊어 줄로 묶는다. 한 조각이 혼자서 폭을 넘으면 그 줄에 그대로 두고 넘치게 한다.
    private func rows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var result: [Row] = []
        var current = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if current.width + size.width > maxWidth, !current.indices.isEmpty {
                result.append(current)
                current = Row()
            }
            current.indices.append(index)
            current.width += size.width
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty { result.append(current) }
        return result
    }

    private var offsetFactor: CGFloat {
        switch alignment {
        case .leading: 0
        case .center: 0.5
        case .trailing: 1
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

#Preview("가운데 정렬 — 줄마다 밀린다") {
    HighlightedText("타이틀을 이렇게 적어주세요 두 번째 줄은 이렇게 입력해주세요", alignment: .center)
        .hilight("이렇게")
        .frame(maxWidth: .infinity)
        .padding(.ds(.p20))
        .background(Color.BlackWhite.white)
}

#Preview("색 6종") {
    VStack(alignment: .leading, spacing: .ds(.p12)) {
        ForEach(HighlightedText.Tone.allCases, id: \.self) { tone in
            HighlightedText("텍스트", typography: .body2).hilightColor(tone)
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}

#Preview("마커 방식 3종 · 아이콘") {
    VStack(alignment: .leading, spacing: .ds(.p16)) {
        HighlightedText("텍스트", typography: .body2).hilightFill(.full)
        HighlightedText("텍스트", typography: .body2).hilightFill(.midlined)
        HighlightedText("텍스트", typography: .body2).hilightFill(.underlined)
        HighlightedText("텍스트", typography: .body2).hilightIcon(Image.Info.default)
        HighlightedText("텍스트", typography: .head3)
            .hilightColor(.black)
            .hilightFill(.midlined)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
