//
//  Pretendard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

/// HILIT 서비스 폰트 패밀리. 타이포 토큰(`DSTypography`)이 쓰는 웨이트만 노출한다.
///
/// 폰트 **등록 코드를 두지 않는다** — Tuist 가 만든 `SharedDesignSystemInterfaceFontFamily` 의
/// 폰트 생성자가 미등록 패밀리를 감지해 스스로 `register()` 를 부른다(첫 사용 시 1회).
/// 이 enum 은 웨이트에 의미(Figma 스타일명 약어)를 입히고 생성 접근자로 잇는 층이다.
public enum Pretendard {
    public enum Weight: String, CaseIterable, Sendable {
        case regular = "Regular"
        case medium = "Medium"
        case semiBold = "SemiBold"
        case bold = "Bold"

        /// PostScript 이름 (예: "Pretendard-SemiBold"). 등록 검증·UIKit 조회용.
        public var postScriptName: String { "Pretendard-\(rawValue)" }

        /// Figma 스타일명의 웨이트 축약 (head1_**sb**_32)
        var figmaAbbreviation: String {
            switch self {
            case .regular: "r"
            case .medium: "m"
            case .semiBold: "sb"
            case .bold: "b"
            }
        }

        /// Tuist 생성 폰트 접근자. otf 를 지우거나 이름을 바꾸면 여기서 컴파일이 깨진다.
        var asset: SharedDesignSystemInterfaceFontConvertible {
            switch self {
            case .regular: SharedDesignSystemInterfaceFontFamily.Pretendard.regular
            case .medium: SharedDesignSystemInterfaceFontFamily.Pretendard.medium
            case .semiBold: SharedDesignSystemInterfaceFontFamily.Pretendard.semiBold
            case .bold: SharedDesignSystemInterfaceFontFamily.Pretendard.bold
            }
        }
    }

    /// 네 웨이트를 한 번에 등록한다. 평상시엔 필요 없다 — 토큰을 쓰는 순간 그 웨이트가 알아서 등록된다.
    /// 아직 안 쓴 웨이트까지 등록돼 있어야 하는 경우(번들 경로 검증 테스트, UIKit 직접 조회)에만 부른다.
    public static func registerAll() {
        SharedDesignSystemInterfaceFontFamily.registerAllCustomFonts()
    }
}
