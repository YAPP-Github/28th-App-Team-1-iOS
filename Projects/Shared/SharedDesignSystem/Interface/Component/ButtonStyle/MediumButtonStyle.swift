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

    @Environment(\.isEnabled) private var isEnabled

    private let tone: Tone

    public init(tone: Tone = .default) {
        self.tone = tone
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(tone.typography)
            .padding(.horizontal, .ds(.p24))
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
    /// 중형 버튼. `.medium()` 기본 · `.medium(.green)` 등 색 6종.
    static func medium(_ tone: MediumButtonStyle.Tone = .default) -> Self {
        MediumButtonStyle(tone: tone)
    }
}

#Preview("medium 6색 + disabled") {
    VStack(spacing: .ds(.p12)) {
        ForEach(Array(MediumButtonStyle.Tone.allCases.enumerated()), id: \.offset) { _, tone in
            Button("버튼") {}.buttonStyle(.medium(tone))
        }
        Button("비활성") {}.buttonStyle(.medium(.green)).disabled(true)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
