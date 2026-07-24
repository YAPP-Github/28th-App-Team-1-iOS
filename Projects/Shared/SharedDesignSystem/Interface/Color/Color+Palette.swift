//
//  Color+Palette.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

// @lat: [[architecture#디자인 시스템]]
// HILIT 색상 팔레트 — Figma «Hilit_Color_Guide»(node 366-173) 확정본과 1:1.
// 에셋명은 HEX(Color636777), 접근은 패밀리 enum 으로. 값은 Colors.xcassets, 로드는 Color.load 단일 seam.
public extension Color {

    enum HilitBlack {
        public static var b800: Color { .load("Color1A1B1F") }   // 메인 블랙·텍스트
        public static var b900: Color { .load("Color121316") }   // 다크모드 배경
    }

    enum HilitGreen {
        public static var g500: Color { .load("ColorACEBA0") }   // 메인 그린
        public static var g600: Color { .load("Color88C97C") }
        public static var g800: Color { .load("Color106100") }   // 그린 텍스트
    }

    enum Error {
        public static var e200: Color { .load("ColorFFEBEB") }   // 레드 배경
        public static var e300: Color { .load("ColorFFA6A6") }
        public static var e400: Color { .load("ColorFF8383") }
        public static var e500: Color { .load("ColorFF5757") }   // 메인 레드·레드 텍스트
    }

    enum Positive {
        public static var p200: Color { .load("ColorDDFAFF") }   // 블루 배경
        public static var p500: Color { .load("Color00CFEF") }   // 메인 블루
        public static var p800: Color { .load("Color008A9F") }   // 블루 텍스트
    }

    enum Gray {
        public static var g50: Color { .load("ColorF6F7F9") }    // 그레이 배경
        public static var g100: Color { .load("ColorEBECF1") }
        public static var g200: Color { .load("ColorBCBEC6") }
        public static var g300: Color { .load("Color9DA0AC") }   // disabled 상태 텍스트
        public static var g400: Color { .load("Color8A8D9C") }
        public static var g500: Color { .load("Color6D7183") }   // 그레이 텍스트
        public static var g600: Color { .load("Color636777") }
        public static var g700: Color { .load("Color494C58") }
        public static var g800: Color { .load("Color31333B") }
        public static var g900: Color { .load("Color27282F") }
    }

    enum BlackWhite {
        public static var white: Color { .load("ColorFFFFFF") }
    }
}
