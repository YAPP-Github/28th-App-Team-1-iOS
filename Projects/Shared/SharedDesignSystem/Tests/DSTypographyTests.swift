//
//  DSTypographyTests.swift
//  SharedDesignSystemTests
//
//  Created by EunseoKim on 26/07/18.
//

import CoreGraphics
import SwiftUI
import Testing
import UIKit
@testable import SharedDesignSystemImplementation

/// Figma «[0722 H/O] HILIT_Text_Guide» 스펙과 토큰 정의의 1:1 을 고정하는 테스트.
/// 스케일 개정 시 이 표부터 Figma 와 대조해 갱신한다.
struct DSTypographyTests {

    @Test("토큰은 Figma 스타일명 25종과 정확히 일치한다")
    func tokenNamesMatchFigmaStyles() {
        let expected: Set<String> = [
            "head1_sb_32", "head2_m_32",
            "head3_b_24", "head4_sb_24", "head5_m_24", "head6_r_24",
            "sub1_sb_22", "sub2_m_22", "sub3_r_22",
            "sub4_sb_20", "sub5_m_20", "sub6_r_20",
            "sub7_sb_18", "sub8_m_18", "sub9_r_18",
            "body1_b_16", "body2_sb_16", "body3_m_16", "body4_r_16",
            "body5_sb_14", "body6_m_14", "body7_r_14",
            "body8_sb_12", "body9_m_12", "body10_r_12"
        ]
        #expect(Set(DSTypography.allCases.map(\.figmaName)) == expected)
    }

    @Test("행간은 Figma 표의 px 열과 일치한다")
    func lineHeightsMatchFigmaTable() {
        let expectedBySize: [CGFloat: CGFloat] = [32: 38, 24: 31, 22: 29, 20: 26, 18: 23, 16: 21, 14: 18, 12: 16]
        for typography in DSTypography.allCases {
            // 24px 층에서 head3·head4 만 135%(32px) — 나머지는 표의 크기별 기본값.
            let expected: CGFloat? = [.head3, .head4].contains(typography) ? 32 : expectedBySize[typography.size]
            #expect(typography.lineHeight == expected)
        }
    }

    @Test("자간은 전 스타일 -2.5% 다")
    func letterSpacingIsMinusTwoPointFivePercentForAllStyles() {
        for typography in DSTypography.allCases {
            #expect(typography.letterSpacing == typography.size * -0.025)
        }
    }

    /// 번들 리소스(otf) → CoreText 등록 → UIFont 로드까지의 실런타임 경로 검증.
    /// static-library 모드에서 Tuist 합성 번들(`Bundle.module`)이 깨지면 여기서 잡힌다.
    @Test("폰트가 번들에서 등록되어 UIFont 로 로드된다")
    func fontsRegisterFromBundleAndLoadAsUIFont() {
        Pretendard.registerAll()   // 토큰을 안 쓴 웨이트까지 등록해 네 개 모두 검사한다
        for weight in Pretendard.Weight.allCases {
            #expect(UIFont(name: weight.postScriptName, size: 16) != nil, "\(weight.postScriptName) 로드 실패")
        }
    }
}
