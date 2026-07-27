//
//  TagLabel.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 소형 사각 태그 — Figma «tag» 1:1. px4 · SemiBold12(.body8) · 모서리 0,
/// 배경/텍스트 토큰만 용도별로 갈아끼운다(기본 = 회색 «선택» 태그 조합).
/// 예: 선택 입력 안내(gray100/gray600), 척도 극 라벨(positive200/positive800 · error200/error500).
public struct TagLabel: View {
    private let text: String
    private let foreground: Color
    private let background: Color

    public init(
        _ text: String,
        foreground: Color = Color.GrayScale.g600,
        background: Color = Color.GrayScale.g100
    ) {
        self.text = text
        self.foreground = foreground
        self.background = background
    }

    public var body: some View {
        Text(text)
            .dsTypography(.body8)
            .foregroundStyle(foreground)
            .padding(.horizontal, .ds(.p4))
            .background(background)
    }
}

#Preview {
    VStack(spacing: .ds(.p12)) {
        TagLabel("선택")
        TagLabel("좋았어요", foreground: Color.Positive.p800, background: Color.Positive.p200)
        TagLabel("아쉬웠어요", foreground: Color.Error.e500, background: Color.Error.e200)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
