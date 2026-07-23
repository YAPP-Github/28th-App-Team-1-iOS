//
//  Color+DS.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

public extension Color {
    /// 원시 팔레트 토큰 → Color. 미러: `Font.ds(_:)`. 특수한 경우용 — 화면 코드는 아래 시맨틱 토큰을 우선한다.
    static func ds(_ token: DSColor) -> Color {
        load(token.assetName)
    }

    // MARK: 시맨틱 토큰 (Figma 용도 주석 기반 — 화면 코드 우선)

    /// 메인 브랜드 그린. → `hilit green/500`
    static var dsPrimary: Color { ds(.hilitGreen500) }
    /// 기본 배경(그레이). → `grayscale/gray-50`
    static var dsBackground: Color { ds(.gray50) }
    /// 기본 텍스트(메인 블랙). → `hilit black/800`
    static var dsTextPrimary: Color { ds(.hilitBlack800) }
    /// 보조 텍스트(그레이). → `grayscale/gray-500`
    static var dsTextSecondary: Color { ds(.gray500) }
    /// 비활성 텍스트. → `grayscale/gray-300`
    static var dsTextDisabled: Color { ds(.gray300) }
    /// 오류(레드) 강조·텍스트. → `error/500`
    static var dsError: Color { ds(.error500) }
    /// 오류 배경(연한 레드). → `error/200`
    static var dsErrorBackground: Color { ds(.error200) }
    /// 긍정(블루) 강조. → `positive/500`
    static var dsPositive: Color { ds(.positive500) }
    /// 긍정 배경(연한 블루). → `positive/200`
    static var dsPositiveBackground: Color { ds(.positive200) }
}
