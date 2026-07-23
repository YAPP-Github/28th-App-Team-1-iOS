//
//  DSColor.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

// @lat: [[architecture#디자인 시스템]]
/// HILIT 색상 팔레트 토큰 — Figma «Hilit_Color_Guide»(node 366-173) 확정본과 1:1.
/// 케이스명은 Figma 색상명을 Swift 식별자로 변환 (hilitBlack800 = "hilit black/800") — 전체 대응은 `figmaName`.
/// 사용: `.foregroundStyle(.dsTextPrimary)`(시맨틱, 화면 코드 우선) 또는 `Color.ds(.gray900)`(원시 팔레트).
public enum DSColor: String, CaseIterable, Sendable {
    // hilit black
    case hilitBlack800, hilitBlack900
    // hilit green
    case hilitGreen500, hilitGreen600, hilitGreen800
    // negative (error)
    case error200, error300, error400, error500
    // positive
    case positive200, positive500, positive800
    // grayscale
    case gray50, gray100, gray200, gray300, gray400, gray500, gray600, gray700, gray800, gray900
    // black & white
    case white
}

public extension DSColor {
    /// Colors.xcassets 콜러셋 이름 (= 케이스명).
    var assetName: String { rawValue }

    /// Figma 색상명 (예: "hilit black/800") — 디자이너 커뮤니케이션·핸드오프 대조용.
    var figmaName: String {
        switch self {
        case .hilitBlack800: "hilit black/800"
        case .hilitBlack900: "hilit black/900"
        case .hilitGreen500: "hilit green/500"
        case .hilitGreen600: "hilit green/600"
        case .hilitGreen800: "hilit green/800"
        case .error200: "error/200"
        case .error300: "error/300"
        case .error400: "error/400"
        case .error500: "error/500"
        case .positive200: "positive/200"
        case .positive500: "positive/500"
        case .positive800: "positive/800"
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
        case .white: "Black-White/white"
        }
    }

    /// Figma 확정 HEX (RRGGBB, 대문자) — 에셋 값 스펙 대조용 (`DSColorTests`).
    var hex: String {
        switch self {
        case .hilitBlack800: "1A1B1F"
        case .hilitBlack900: "121316"
        case .hilitGreen500: "ACEBA0"
        case .hilitGreen600: "88C97C"
        case .hilitGreen800: "106100"
        case .error200: "FFEBEB"
        case .error300: "FFA6A6"
        case .error400: "FF8383"
        case .error500: "FF5757"
        case .positive200: "DDFAFF"
        case .positive500: "00CFEF"
        case .positive800: "008A9F"
        case .gray50: "F6F7F9"
        case .gray100: "EBECF1"
        case .gray200: "BCBEC6"
        case .gray300: "9DA0AC"
        case .gray400: "8A8D9C"
        case .gray500: "6D7183"
        case .gray600: "636777"
        case .gray700: "494C58"
        case .gray800: "31333B"
        case .gray900: "27282F"
        case .white: "FFFFFF"
        }
    }
}
