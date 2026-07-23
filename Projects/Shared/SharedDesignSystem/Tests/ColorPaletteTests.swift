//
//  ColorPaletteTests.swift
//  SharedDesignSystemTests
//
//  Created by EunseoKim on 26/07/23.
//

import CoreGraphics
import SwiftUI
import Testing
import UIKit
@testable import SharedDesignSystemImplementation

/// 팔레트 토큰이 Figma «Hilit_Color_Guide»(node 366-173) 확정 HEX 로 로드되는지 고정하는 테스트.
/// (enum 매핑 → 에셋(Color<HEX>) → 번들 로드 → RGB 를 한 번에 검증. 팔레트 개정 시 이 표를 Figma 와 대조.)
struct ColorPaletteTests {

    @Test("팔레트 색상이 Figma 확정 HEX 와 일치한다")
    func paletteColorsMatchFigmaHex() {
        let cases: [(token: Color, hex: String)] = [
            (Color.HilitBlack.b800, "1A1B1F"), (Color.HilitBlack.b900, "121316"),
            (Color.HilitGreen.g500, "ACEBA0"), (Color.HilitGreen.g600, "88C97C"), (Color.HilitGreen.g800, "106100"),
            (Color.Error.e200, "FFEBEB"), (Color.Error.e300, "FFA6A6"), (Color.Error.e400, "FF8383"), (Color.Error.e500, "FF5757"),
            (Color.Positive.p200, "DDFAFF"), (Color.Positive.p500, "00CFEF"), (Color.Positive.p800, "008A9F"),
            (Color.Gray.g50, "F6F7F9"), (Color.Gray.g100, "EBECF1"), (Color.Gray.g200, "BCBEC6"), (Color.Gray.g300, "9DA0AC"),
            (Color.Gray.g400, "8A8D9C"), (Color.Gray.g500, "6D7183"), (Color.Gray.g600, "636777"), (Color.Gray.g700, "494C58"),
            (Color.Gray.g800, "31333B"), (Color.Gray.g900, "27282F"),
            (Color.BlackWhite.white, "FFFFFF")
        ]

        #expect(cases.count == 23)
        for (token, hex) in cases {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            UIColor(token).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let actual = String(
                format: "%02X%02X%02X",
                Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded())
            )
            #expect(actual == hex, "기대 \(hex), 실제 \(actual)")
        }
    }
}
