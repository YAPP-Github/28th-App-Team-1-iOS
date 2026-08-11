//
//  MediumButtonStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

// Figma: «button-medium» — 시트 축: status(행) = outlined · filled / color(열) = default·green·gray·blue·red
//        + disabled 열. filled 행에는 black 하나뿐이다.

import SwiftUI

/// 중형 버튼 — h45 · px24/py12 · 직각 · hug. «온보딩 및 지인 피드백 버튼으로 사용».
///
/// 시트는 **status 행 × color 열** 두 축이지만 **행이 색에서 결정된다** — outlined 행에 default·green·
/// gray·blue·red, filled 행에 black 하나. 같은 색이 두 행에 걸치는 칸이 없어서 `Style` 은 파라미터가
/// 아니라 `Tone` 의 파생값이다(파라미터로 두면 `.medium(.black, style: .filled)` 처럼 되풀이만 늘고
/// 잘못된 조합을 만들 수 있다). 한 색이 두 행을 갖게 되면 그때 파라미터로 승격한다.
/// `mini` 는 black 이 default·outlined 두 칸을 다 가져서 거기선 `style` 이 진짜 파라미터다.
///
/// disabled 열은 색과 무관하게 한 룩(g50 바탕·g300 테두리·g300 글자)으로 수렴한다 — 색이 아니라
/// `isEnabled` 가 처리하는 상태다.
public struct MediumButtonStyle: ButtonStyle {
    /// Figma `status` 축(시트 행). `Tone` 에서 파생되며 테두리 유무를 가른다.
    public enum Style: Sendable, CaseIterable {
        /// 테두리 있음 — 채움은 색마다 다르다(default·gray 는 흰 판, green·blue·red 는 옅은 색 판).
        case outlined
        /// 테두리 없는 채움 — 시트에 black 한 칸뿐.
        case filled

        /// 이 행에 속한 색 — 시트의 한 줄. 카탈로그·프리뷰가 시트를 그대로 재현할 때 쓴다.
        public var tones: [Tone] {
            Tone.allCases.filter { $0.style == self }
        }
    }

    /// Figma `color` 축(시트 열). disabled 는 상태라서 여기 없다.
    public enum Tone: Sendable, CaseIterable {
        case `default`, black, gray, green, blue, red

        /// 이 색이 속한 시트 행 — black 만 filled, 나머지는 outlined.
        public var style: Style {
            self == .black ? .filled : .outlined
        }

        /// blue·red 만 SemiBold — Figma 원본이 그렇다.
        var typography: DSTypography {
            switch self {
            case .blue, .red: .body2
            default: .body3
            }
        }

        var foreground: Color {
            switch self {
            case .default: Color.HilitBlack.b800
            case .black: Color.BlackWhite.white
            case .gray: Color.GrayScale.g700
            case .green: Color.HilitGreen.g800
            case .blue: Color.Positive.p800
            case .red: Color.Error.e500
            }
        }

        var background: Color {
            switch self {
            case .default, .gray: Color.BlackWhite.white
            case .black: Color.HilitBlack.b800
            case .green: Color.HilitGreen.g500
            case .blue: Color.Positive.p200
            case .red: Color.Error.e200
            }
        }

        /// filled 행(black)은 테두리가 없다 — 시트가 그렇게 갈라져 있다.
        var border: Color? {
            switch self {
            case .default: Color.GrayScale.g200
            case .black: nil
            case .gray: Color.GrayScale.g100
            case .green: Color.HilitGreen.g600
            case .blue: Color.Positive.p500
            case .red: Color.Error.e500
            }
        }
    }

    /// 폭을 어떻게 잡는가.
    public enum Layout: Sendable {
        /// 라벨 크기만큼 (기본) — px24.
        case hug
        /// 주어진 폭을 채운다 — HStack 에 나란히 놓아 N지선다 등폭 칩을 만들 때.
        /// Figma «button-medium» 등폭 셀은 라벨을 한 줄 가운데 정렬하므로 가로 패딩을 두지 않는다
        /// (두면 긴 카피에서 라벨 폭이 남지 않아 밀리거나 줄바꿈된다). 넘치면 축소해 한 줄을 지킨다.
        case fill
    }

    @Environment(\.isEnabled) private var isEnabled

    private let tone: Tone
    private let layout: Layout

    public init(tone: Tone = .default, layout: Layout = .hug) {
        self.tone = tone
        self.layout = layout
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(tone.typography)
            .lineLimit(layout == .fill ? 1 : nil)
            .minimumScaleFactor(layout == .fill ? 0.6 : 1)
            .frame(maxWidth: layout == .fill ? .infinity : nil)
            .padding(.horizontal, layout == .fill ? 0 : .ds(.p24))
            .padding(.vertical, .ds(.p12))
            .foregroundStyle(isEnabled ? tone.foreground : Color.GrayScale.g300)
            .background(isEnabled ? tone.background : Color.GrayScale.g50)
            .overlay {
                if let border = isEnabled ? tone.border : Color.GrayScale.g300 {
                    Rectangle().strokeBorder(border, lineWidth: .ds(.medium))
                }
            }
            .contentShape(Rectangle())
    }
}

public extension ButtonStyle where Self == MediumButtonStyle {
    /// 중형 버튼. `.medium()` 기본 · `.medium(.green)` 색 6종 · `.medium(.blue, layout: .fill)` 등폭 칩.
    static func medium(
        _ tone: MediumButtonStyle.Tone = .default,
        layout: MediumButtonStyle.Layout = .hug
    ) -> Self {
        MediumButtonStyle(tone: tone, layout: layout)
    }
}

#Preview("medium — 시트 매트릭스(status 행 × color 열)") {
    // Figma 시트 그대로: outlined 행 5색 + disabled, filled 행은 black 하나.
    VStack(alignment: .leading, spacing: .ds(.p16)) {
        ForEach(MediumButtonStyle.Style.allCases, id: \.self) { style in
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                Text(String(describing: style)).dsTypography(.body6)
                HStack(spacing: .ds(.p8)) {
                    ForEach(style.tones, id: \.self) { tone in
                        Button("버튼") {}.buttonStyle(.medium(tone))
                    }
                    if style == .outlined {
                        Button("버튼") {}.buttonStyle(.medium()).disabled(true)
                    }
                }
            }
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}

#Preview("medium 6색 + disabled") {
    VStack(spacing: .ds(.p12)) {
        ForEach(Array(MediumButtonStyle.Tone.allCases.enumerated()), id: \.offset) { _, tone in
            Button("버튼") {}.buttonStyle(.medium(tone))
        }
        Button("비활성") {}.buttonStyle(.medium(.green)).disabled(true)

        // 등폭 척도 칩 — 미선택 gray / 선택 blue·red
        HStack(spacing: .ds(.p8)) {
            Button("잘 맞춤") {}.buttonStyle(.medium(.blue, layout: .fill))
            Button("꽤 맞춤") {}.buttonStyle(.medium(.gray, layout: .fill))
            Button("가끔 피함") {}.buttonStyle(.medium(.gray, layout: .fill))
            Button("자주 피함") {}.buttonStyle(.medium(.red, layout: .fill))
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
