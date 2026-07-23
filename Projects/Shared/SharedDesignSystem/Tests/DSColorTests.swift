//
//  DSColorTests.swift
//  SharedDesignSystemTests
//
//  Created by 서정원 on 26/07/22.
//

import SwiftUI
import Testing
import UIKit
@testable import SharedDesignSystemImplementation

/// 시맨틱 색 별칭이 의도한 프리미티브를 가리키는지 고정한다. 별칭 재매핑 시 이 표부터 대조.
struct DSColorTests {

    /// 시맨틱 별칭이 의도한 프리미티브와 동일 RGBA 로 해석되는지 (UIColor 성분 비교 — Color == 불안정 회피).
    @Test("시맨틱 별칭은 지정 프리미티브를 가리킨다")
    func semanticAliasesMapToExpectedPrimitives() {
        let pairs: [(Color, DSColorToken)] = [
            (.dsBrand, .green800), (.dsBrandSoft, .green500),
            (.dsBgLight, .gray50), (.dsBgDark, .black800), (.dsSurfaceDark, .gray900),
            (.dsTextPrimary, .gray900), (.dsTextOnDark, .white),
            (.dsTextSecondary, .gray500), (.dsTextTertiary, .gray400),
            (.dsSeparator, .gray100), (.dsPositive, .positive500), (.dsError, .error500)
        ]
        for (semantic, primitive) in pairs {
            #expect(rgba8(semantic) == rgba8(primitive.color), "별칭이 \(primitive) 와 불일치")
        }
    }

    /// Color → 반올림된 8비트 (red,green,blue,alpha) 성분. sRGB 색 대상.
    private func rgba8(_ color: Color) -> [Int] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
    }
}
