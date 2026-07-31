//
//  Color+Extension.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

/// Tuist 가 Colors.xcassets 를 스캔해 만드는 접근자(`Derived/Sources/TuistAssets+…`)의 축약.
/// 에셋을 지우거나 이름을 바꾸면 여기서 **컴파일이 깨진다** — 문자열 로드였을 땐 런타임에야 드러났다.
private typealias Asset = SharedDesignSystemInterfaceAsset

// @lat: [[architecture#디자인 시스템]]
// HILIT 색상 팔레트 23색 — Figma «Hilit_Color_Guide»(node 366-173) 확정본과 1:1.
// 에셋명은 HEX(Color636777) 라 그대로 쓰면 의미가 사라진다 — 이 패밀리 enum 이 의미를 입히는 층이다.
// 카탈로그도 같은 6개 그룹으로 묶여 있다(HilitBlack·HilitGreen·Error·Positive·GrayScale·BlackWhite).
// `Brand` 는 팔레트 밖 — 제품 색이 아니라 외부 서비스가 지정한 색이라 단계(500/800)를 갖지 않는다.
// 폴더는 정리용이라 namespace 를 잡지 않는다 — 그래서 생성 접근자 이름은 평평한 `colorXXXXXX` 그대로다.
public extension Color {

    /// 외부 서비스 브랜드 색 — 팔레트 23색에 속하지 않는다.
    /// 제품 팔레트와 섞지 않기 위해 별도 패밀리로 둔다(단계 번호 없음, 서비스명이 멤버명).
    /// 해당 서비스의 브랜드 가이드가 진실이라 디자이너가 임의로 못 바꾼다 — 값 변경은 가이드 개정 시에만.
    enum Brand {
        public static var kakao: Color { Asset.Colors.colorFEE500.swiftUIColor }   // 카카오 옐로
    }

    enum HilitBlack {
        public static var b800: Color { Asset.Colors.color1A1B1F.swiftUIColor }   // 메인 블랙·텍스트
        public static var b900: Color { Asset.Colors.color121316.swiftUIColor }   // 다크모드 배경
    }

    enum HilitGreen {
        public static var g500: Color { Asset.Colors.colorACEBA0.swiftUIColor }   // 메인 그린
        public static var g600: Color { Asset.Colors.color88C97C.swiftUIColor }
        public static var g800: Color { Asset.Colors.color106100.swiftUIColor }   // 그린 텍스트
    }

    /// Figma 의 «negative» 그룹 — 코드·카탈로그는 Error 로 통일한다.
    enum Error {
        public static var e200: Color { Asset.Colors.colorFFEBEB.swiftUIColor }   // 레드 배경
        public static var e300: Color { Asset.Colors.colorFFA6A6.swiftUIColor }
        public static var e400: Color { Asset.Colors.colorFF8383.swiftUIColor }
        public static var e500: Color { Asset.Colors.colorFF5757.swiftUIColor }   // 메인 레드·레드 텍스트
    }

    enum Positive {
        public static var p200: Color { Asset.Colors.colorDDFAFF.swiftUIColor }   // 블루 배경
        public static var p500: Color { Asset.Colors.color00CFEF.swiftUIColor }   // 메인 블루
        public static var p800: Color { Asset.Colors.color008A9F.swiftUIColor }   // 블루 텍스트
    }

    enum GrayScale {
        public static var g50: Color { Asset.Colors.colorF6F7F9.swiftUIColor }    // 그레이 배경
        public static var g100: Color { Asset.Colors.colorEBECF1.swiftUIColor }
        public static var g200: Color { Asset.Colors.colorBCBEC6.swiftUIColor }
        public static var g300: Color { Asset.Colors.color9DA0AC.swiftUIColor }   // disabled 상태 텍스트
        public static var g400: Color { Asset.Colors.color8A8D9C.swiftUIColor }
        public static var g500: Color { Asset.Colors.color6D7183.swiftUIColor }   // 그레이 텍스트
        public static var g600: Color { Asset.Colors.color636777.swiftUIColor }
        public static var g700: Color { Asset.Colors.color494C58.swiftUIColor }
        public static var g800: Color { Asset.Colors.color31333B.swiftUIColor }
        public static var g900: Color { Asset.Colors.color27282F.swiftUIColor }
    }

    enum BlackWhite {
        public static var white: Color { Asset.Colors.colorFFFFFF.swiftUIColor }
    }
}
