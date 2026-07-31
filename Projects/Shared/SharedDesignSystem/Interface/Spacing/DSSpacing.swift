//
//  DSSpacing.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/22.
//

import CoreGraphics

// @lat: [[architecture#디자인 시스템]]
/// HILIT 간격 토큰 — Figma padding 스케일(4·8·10·12·14·16·20·22·24·40) 1:1.
/// 사용: `.padding(.ds(.p20))`.
public enum DSSpacing: CaseIterable, Sendable {
    case p4, p8, p10, p12, p14, p16, p20, p22, p24, p40

    public var value: CGFloat {
        switch self {
        case .p4: 4
        case .p8: 8
        case .p10: 10
        case .p12: 12
        case .p14: 14
        case .p16: 16
        case .p20: 20
        case .p22: 22
        case .p24: 24
        case .p40: 40
        }
    }
}

/// HILIT 테두리 두께 토큰 — Figma outline 스케일(outline-s/m/sb/large/mega).
/// 케이스명은 Swift 식별자 규칙(≥2자)에 맞춰 small/medium/semiBold 로 풂 — 값은 Figma 그대로.
/// 사용: `.strokeBorder(…, lineWidth: .ds(.medium))`.
public enum DSOutline: CaseIterable, Sendable {
    case small, medium, semiBold, large, mega

    public var value: CGFloat {
        switch self {
        case .small: 1        // outline-s
        case .medium: 1.2     // outline-m
        case .semiBold: 1.5   // outline-sb
        case .large: 4
        case .mega: 6
        }
    }
}

public extension CGFloat {
    static func ds(_ spacing: DSSpacing) -> CGFloat { spacing.value }
    static func ds(_ outline: DSOutline) -> CGFloat { outline.value }
}
