//
//  TitleBox.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/30.
//

// Figma: «title-box» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2094-7912
//        «title»     https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2044-1856

import SwiftUI

/// 화면 머리글 — Figma «title-box» 1:1. «뱃지 · 타이틀 · 서브 타이틀» 의 수직 리듬(8/4)과
/// 판(light/dark)에 따른 글자색을 소유한다.
///
/// ```swift
/// TitleBox(
///     [.init("타이틀을 이렇게 적어주세요", highlight: "이렇게"),
///      .init("두 번째 줄은 이렇게 입력해주세요", highlight: "이렇게")],
///     tag: "필수",
///     sub: "서브 타이틀을 입력해주세요"
/// )
///
/// TitleBox(["제목만 있는 화면"], alignment: .center)   // 마커 없는 줄은 문자열 리터럴로
/// ```
///
/// Figma `status` 축(left/middle)은 `alignment`, `light/dark` 축은 `.hilitSurface(_:)` Environment —
/// 판은 화면 전체에 걸리는 성질이라 파라미터로 받지 않는다. `show`·`showSub`·`showTag` 축은 파라미터가
/// 아니라 **값의 유무에서 파생**된다(줄 수 · `sub`/`tag` 의 nil).
///
/// Figma 컴포넌트는 좌우 padding 20 을 안에 갖고 있지만 여기선 뺐다 — 화면이 이미 콘텐츠 열 전체에
/// 20 을 주고 있어 그대로 옮기면 40 이 된다. **폭·좌우 여백은 호출부 몫이다.**
public struct TitleBox: View {
    /// 타이틀 한 줄 — 문장 전체와 그 줄에서 마커를 칠할 부분.
    ///
    /// `highlight` 를 주지 않으면 마커 없는 평문 줄이다 (`HighlightedText` 는 강조 부분을 지정하지 않으면
    /// 문장 전체를 칠하므로, 그 경우엔 `Text` 로 그린다).
    public struct Line: Sendable, Hashable, ExpressibleByStringLiteral {
        let text: String
        let highlight: String?

        public init(_ text: String, highlight: String? = nil) {
            self.text = text
            self.highlight = highlight
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }
    }

    private let lines: [Line]
    private let tag: String?
    private let sub: String?
    private let alignment: TextAlignment

    @Environment(\.hilitSurface) private var surface

    public init(
        _ lines: [Line],
        tag: String? = nil,
        sub: String? = nil,
        alignment: TextAlignment = .leading
    ) {
        self.lines = lines
        self.tag = tag
        self.sub = sub
        self.alignment = alignment
    }

    public var body: some View {
        VStack(alignment: horizontalAlignment, spacing: .ds(.p8)) {
            if let tag {
                TagLabel(tag, style: .blackGreen)
            }
            VStack(alignment: horizontalAlignment, spacing: .ds(.p4)) {
                // 줄 사이 간격 0 — 행간은 타이포 토큰이 이미 위아래 패딩으로 갖고 있다.
                VStack(alignment: horizontalAlignment, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        titleLine(line)
                    }
                }
                if let sub {
                    Text(sub)
                        .dsTypography(.body4)
                        .foregroundStyle(subForeground)
                        .multilineTextAlignment(alignment)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    @ViewBuilder
    private func titleLine(_ line: Line) -> some View {
        if let highlight = line.highlight {
            HighlightedText(
                line.text,
                typography: .head3,
                alignment: alignment,
                plainForeground: titleForeground
            )
            .hilight(highlight)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
        } else {
            Text(line.text)
                .dsTypography(.head3)
                .foregroundStyle(titleForeground)
                .multilineTextAlignment(alignment)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }

    private var titleForeground: Color {
        switch surface {
        case .light: Color.HilitBlack.b800
        case .dark: Color.BlackWhite.white
        }
    }

    private var subForeground: Color {
        switch surface {
        case .light: Color.GrayScale.g500
        case .dark: Color.GrayScale.g300
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

#Preview("light — 왼쪽 / 가운데") {
    VStack(spacing: .ds(.p24)) {
        TitleBox(
            [
                .init("타이틀을 이렇게 적어주세요", highlight: "이렇게"),
                .init("두 번째 줄은 이렇게 입력해주세요", highlight: "이렇게")
            ],
            tag: "필수",
            sub: "서브 타이틀을 입력해주세요"
        )
        TitleBox(
            [
                .init("타이틀을 이렇게 적어주세요", highlight: "이렇게"),
                .init("두 번째 줄은 이렇게 입력해주세요", highlight: "이렇게")
            ],
            tag: "필수",
            sub: "서브 타이틀을 입력해주세요",
            alignment: .center
        )
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.BlackWhite.white)
}

#Preview("dark — 판은 .hilitSurface(.dark)") {
    VStack(spacing: .ds(.p24)) {
        TitleBox(
            [
                .init("타이틀을 이렇게 적어주세요", highlight: "이렇게"),
                .init("두 번째 줄은 이렇게 입력해주세요", highlight: "이렇게")
            ],
            tag: "필수",
            sub: "서브 타이틀을 입력해주세요"
        )
        TitleBox(
            [.init("타이틀을 이렇게 적어주세요", highlight: "이렇게")],
            sub: "서브 타이틀을 입력해주세요",
            alignment: .center
        )
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
    .hilitSurface(.dark)
}

#Preview("뱃지·서브 없음 · 마커 없는 줄") {
    VStack(alignment: .leading, spacing: .ds(.p24)) {
        TitleBox([.init("타이틀만 이렇게", highlight: "이렇게")])
        TitleBox(["마커 없는 평문 타이틀"], sub: "서브 타이틀을 입력해주세요")
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.BlackWhite.white)
}
