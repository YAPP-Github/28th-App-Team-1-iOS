//
//  TagLabel.swift
//  SharedDesignSystem
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 소형 사각 태그 — Figma «tag» 1:1. 모서리 0.
///
/// 시트는 **padding 행 × 색조합 열** 두 축이다:
/// - 행 = `Size` — `padding=0px`(`.compact` — px4 · `body6` Medium14) / `padding=4px`(`.regular` — px12·py4 · `body5` SemiBold14)
/// - 열 = `Style` — 시트 칸 이름이 «배경-글자» 축약(`b-gr` = black 배경 + green 글자)이라 그걸 풀어 쓴다
///
/// 두 행에 다 있는 칸은 `blackGreen`·`grayGray` 뿐이고 나머지는 한 행 전용이다 — `Size` 는 진짜 축이라
/// 파라미터로 두고, 시트에 없는 조합은 `init` assert 로 막는다(`Style.sizes` 가 그 행 목록).
/// 색을 열린 `Color` 파라미터로 받던 이전 API 는 시트에 없는 조합을 만들 수 있어 닫았다.
public struct TagLabel: View {
    /// Figma `padding` 축(시트 행). 이름은 Figma 값(`0px`/`4px`)이 Swift 식별자가 못 돼 역할로 바꿨다.
    public enum Size: Sendable, CaseIterable {
        /// `padding=0px` — px4 · `body6`(Medium 14). 세로 여백 없음.
        case compact
        /// `padding=4px` — px12 · py4 · `body5`(SemiBold 14).
        case regular

        /// 이 행에 있는 색조합 — 시트의 한 줄. 카탈로그·프리뷰가 시트를 그대로 재현할 때 쓴다.
        public var styles: [Style] {
            Style.allCases.filter { $0.sizes.contains(self) }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: .ds(.p4)
            case .regular: .ds(.p12)
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: 0
            case .regular: .ds(.p4)
            }
        }

        var typography: DSTypography {
            switch self {
            case .compact: .body6
            case .regular: .body5
            }
        }
    }

    /// Figma 색조합 축(시트 열). 이름은 시트 칸의 «배경-글자» 축약을 푼 것 — `blackGreen` = `b-gr`.
    public enum Style: Sendable, CaseIterable {
        /// `b-gr` — 검정 판 + 형광 연두 글자 (`TitleBox` 의 «필수» 뱃지)
        case blackGreen
        /// `g-g` — 옅은 회색 판 + 회색 글자 (기본, «선택» 안내)
        case grayGray
        /// `dg-gr` — 짙은 회색 판 + 형광 연두 글자
        case darkGrayGreen
        /// `dg-white` — 짙은 회색 판 + 흰 글자
        case darkGrayWhite
        /// `dg-g` — 더 짙은 회색 판(g900) + 옅은 회색 글자(g200). 다른 `dg-*` 보다 판이 한 단 어둡다.
        case darkGrayGray
        /// `n-g` — 판 없음(투명) + 회색 글자
        case noneGray
        /// `w-b` — 흰 판 + 검정 글자
        case whiteBlack
        /// `gr-gr` — 연두 판 + 짙은 초록 글자
        case greenGreen
        /// `r-r` — 연분홍 판 + 빨강 글자 (척도 부정 극)
        case redRed
        /// `b-b` — 연하늘 판 + 파랑 글자 (척도 긍정 극)
        case blueBlue

        /// 이 색조합이 존재하는 시트 행. 대부분 한 행 전용이다.
        public var sizes: [Size] {
            switch self {
            case .blackGreen, .grayGray: [.compact, .regular]
            case .darkGrayGreen, .darkGrayWhite, .darkGrayGray, .noneGray, .whiteBlack: [.regular]
            case .greenGreen, .redRed, .blueBlue: [.compact]
            }
        }

        var foreground: Color {
            switch self {
            case .blackGreen, .darkGrayGreen: Color.HilitGreen.g500
            case .grayGray, .noneGray: Color.GrayScale.g600
            // 다크 판 위 g600 글자는 판(g900)과 명도가 붙어 거의 안 읽힌다 — 시트 `dg-g` 대로 g200.
            case .darkGrayGray: Color.GrayScale.g200
            case .darkGrayWhite: Color.BlackWhite.white
            case .whiteBlack: Color.HilitBlack.b800
            case .greenGreen: Color.HilitGreen.g800
            case .redRed: Color.Error.e500
            case .blueBlue: Color.Positive.p800
            }
        }

        var background: Color {
            switch self {
            case .blackGreen: Color.HilitBlack.b800
            case .grayGray: Color.GrayScale.g100
            case .darkGrayGreen, .darkGrayWhite: Color.GrayScale.g800
            case .darkGrayGray: Color.GrayScale.g900
            case .noneGray: .clear
            case .whiteBlack: Color.BlackWhite.white
            case .greenGreen: Color.HilitGreen.g500
            case .redRed: Color.Error.e200
            case .blueBlue: Color.Positive.p200
            }
        }
    }

    private let text: String
    private let style: Style
    private let size: Size

    /// - Parameters:
    ///   - text: 태그 문구.
    ///   - style: 색조합 (시트 열). 기본은 «선택» 안내에 쓰는 `g-g`.
    ///   - size: padding 행. 기본은 현재 화면들이 쓰는 `0px` 계열.
    public init(_ text: String, style: Style = .grayGray, size: Size = .compact) {
        assert(
            style.sizes.contains(size),
            "시트에 없는 조합이다 — \(style) 은 \(style.sizes) 행에만 있다."
        )
        self.text = text
        self.style = style
        self.size = size
    }

    public var body: some View {
        Text(text)
            .dsTypography(size.typography)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(style.background)
    }
}

#Preview("tag — 시트 매트릭스(padding 행 × 색조합 열)") {
    VStack(alignment: .leading, spacing: .ds(.p16)) {
        ForEach(TagLabel.Size.allCases, id: \.self) { size in
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                Text(String(describing: size)).dsTypography(.body6)
                HStack(spacing: .ds(.p12)) {
                    ForEach(size.styles, id: \.self) { style in
                        TagLabel("텍스트", style: style, size: size)
                    }
                }
            }
        }
    }
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}
