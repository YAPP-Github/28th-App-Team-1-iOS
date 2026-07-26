//
//  MediumButtonStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

// Figma: «ButtonMedium» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=1941-3261

import SwiftUI

/// 중형 버튼 — h45 · px24/py12 · 직각 · hug. 색 축 6종만 갖고,
/// **disabled 는 어떤 색이든 같은 룩(g50 바탕·g300 테두리·g300 글자)으로 수렴**한다 —
/// 그래서 disabled 는 색이 아니라 `isEnabled` 가 처리하는 상태다.
public struct MediumButtonStyle: ButtonStyle {
    /// Figma `color` 축 (disabled 제외 — 상태라서 뺐다).
    public enum Tone: Sendable, CaseIterable {
        case `default`, black, gray, green, blue, red

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

        /// black 만 테두리 없음 — Figma `status=outlined` 인데도 스트로크가 없다(시안 그대로).
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
