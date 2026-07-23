//
//  DSColorTests.swift
//  SharedDesignSystemTests
//
//  Created by EunseoKim on 26/07/23.
//

import CoreGraphics
import SwiftUI
import Testing
import UIKit
@testable import SharedDesignSystemImplementation

/// Figma «Hilit_Color_Guide»(node 366-173) 확정본과 토큰·에셋의 1:1 을 고정하는 테스트.
/// 팔레트 개정 시 이 표부터 Figma 와 대조해 갱신한다.
struct DSColorTests {

    @Test("토큰은 Figma 색상명 23종과 정확히 일치한다")
    func tokenNamesMatchFigmaColors() {
        let expected: Set<String> = [
            "hilit black/800", "hilit black/900",
            "hilit green/500", "hilit green/600", "hilit green/800",
            "error/200", "error/300", "error/400", "error/500",
            "positive/200", "positive/500", "positive/800",
            "grayscale/gray-50", "grayscale/gray-100", "grayscale/gray-200",
            "grayscale/gray-300", "grayscale/gray-400", "grayscale/gray-500",
            "grayscale/gray-600", "grayscale/gray-700", "grayscale/gray-800", "grayscale/gray-900",
            "Black-White/white"
        ]
        #expect(Set(DSColor.allCases.map(\.figmaName)) == expected)
    }

    /// 에셋(Colors.xcassets)에서 로드한 실제 RGB 가 Figma 확정 HEX 와 일치하는지 — 콜러셋 오타·번들 로드 동시 검증.
    /// `Color.ds(_:)` 경로로 로드하므로 static-library 모드에서 Tuist 합성 번들(Bundle.module)이 깨지면 여기서 잡힌다.
    @Test("에셋 색상이 Figma 확정 HEX 와 일치한다", arguments: DSColor.allCases)
    func assetColorMatchesFigmaHex(_ token: DSColor) {
        let uiColor = UIColor(Color.ds(token))   // 에셋 누락 시 load() 의 DEBUG assert 가 먼저 잡는다
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let actual = String(
            format: "%02X%02X%02X",
            Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded())
        )
        #expect(actual == token.hex, "\(token.figmaName): 에셋 \(actual) ≠ 스펙 \(token.hex)")
    }
}
