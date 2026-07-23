//
//  DSColorToken.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/22.
//

import SwiftUI

// @lat: [[architecture#디자인 시스템]]
/// HILIT 색상 프리미티브 토큰 — Figma «Part4 지인 피드백 · 여기가 최종» 변수와 1:1.
/// 케이스명은 Swift 식별자(예: green500), 원 변수 경로는 `figmaName` 참조.
/// 사용: `Color.ds(.green800)` — 화면 코드는 시맨틱 별칭(`Color.dsBrand` 등)을 우선.
public enum DSColorToken: String, CaseIterable, Sendable {
    case green500, green600, green800
    case gray50, gray100, gray200, gray300, gray400, gray500, gray600, gray700, gray800, gray900
    case white, black800
    case positive200, positive500, positive800
    case error200, error500

    /// 0xRRGGBB 정수값 (Figma hex).
    public var hex: UInt32 {
        switch self {
        case .green500: 0xACEBA0
        case .green600: 0x88C97C
        case .green800: 0x106100
        case .gray50: 0xF6F7F9
        case .gray100: 0xEBECF1
        case .gray200: 0xBCBEC6
        case .gray300: 0x9DA0AC
        case .gray400: 0x8A8D9C
        case .gray500: 0x6D7183
        case .gray600: 0x636777
        case .gray700: 0x494C58
        case .gray800: 0x31333B
        case .gray900: 0x27282F
        case .white: 0xFFFFFF
        case .black800: 0x1A1B1F
        case .positive200: 0xDDFAFF
        case .positive500: 0x00CFEF
        case .positive800: 0x008A9F
        case .error200: 0xFFEBEB
        case .error500: 0xFF5757
        }
    }

    /// 토큰의 SwiftUI Color (sRGB, 불투명).
    public var color: Color { Color(dsHex: hex) }

    /// Figma 변수 경로 — 디자이너 핸드오프 대조용 (예: "hilit green/500").
    public var figmaName: String {
        switch self {
        case .green500: "hilit green/500"
        case .green600: "hilit green/600"
        case .green800: "hilit green/800"
        case .gray50: "grayscale/gray-50"
        case .gray100: "grayscale/gray-100"
        case .gray200: "grayscale/gray-200"
        case .gray300: "grayscale/gray-300"
        case .gray400: "grayscale/gray-400"
        case .gray500: "grayscale/gray-500"
        case .gray600: "grayscale/gray-600"
        case .gray700: "grayscale/gray-700"
        case .gray800: "grayscale/gray-800"
        case .gray900: "grayscale/gray-900"
        case .white: "black_and_white/white"
        case .black800: "hilit black/800"
        case .positive200: "positive/200"
        case .positive500: "positive/500"
        case .positive800: "positive/800"
        case .error200: "error/200"
        case .error500: "error/500"
        }
    }
}

extension Color {
    /// 0xRRGGBB → sRGB Color. 토큰 정의 전용(모듈 내부).
    init(dsHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
