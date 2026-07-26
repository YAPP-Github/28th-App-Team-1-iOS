//
//  HighlightedText.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 형광펜 마커 텍스트 — Figma «highlighted-text» 1:1. `Parallelogram` 배경 + 양옆 8pt
/// (경사 4 + 평면 4) 규약을 한 곳에 고정한 래퍼. 타이틀 마커(head3 · 그린)와
/// 요약 라벨 칩(body3 · 톤 배경) 이 같은 컴포넌트의 파라미터 차이다.
public struct HighlightedText: View {
    private let text: String
    private let typography: DSTypography
    private let foreground: Color
    private let background: Color

    public init(
        _ text: String,
        typography: DSTypography = .head3,
        foreground: Color = Color.GrayScale.g900,
        background: Color = Color.HilitGreen.g500
    ) {
        self.text = text
        self.typography = typography
        self.foreground = foreground
        self.background = background
    }

    public var body: some View {
        Text(text)
            .dsTypography(typography)
            .foregroundStyle(foreground)
            .padding(.horizontal, .ds(.p8))
            .background(background, in: Parallelogram())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .ds(.p16)) {
        HighlightedText("이렇게 전달")                                   // 타이틀 마커 기본형
        HighlightedText(
            "좋았어요",
            typography: .body3,
            foreground: Color.Positive.p800,
            background: Color.Positive.p200
        )                                                               // 요약 라벨 칩
        HighlightedText(
            "-",
            typography: .body3,
            foreground: Color.GrayScale.g600,
            background: Color.GrayScale.g100
        )                                                               // 미선택 중립
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
