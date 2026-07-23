//
//  Color+DS.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/22.
//

import SwiftUI

public extension Color {
    /// 프리미티브 토큰 → Color. 화면 코드는 아래 시맨틱 별칭을 우선 쓴다.
    static func ds(_ token: DSColorToken) -> Color { token.color }

    // MARK: - 시맨틱 별칭 (잠정 — 화면 단계에서 실제 컴포넌트에 대보며 확정)
    // 최종 디자인은 화면마다 고정 톤(라이트/다크)을 쓰므로 이름에 톤을 명시한다.

    /// primary 액션·강조.
    static let dsBrand = DSColorToken.green800.color
    /// 옅은 강조·선택 배경.
    static let dsBrandSoft = DSColorToken.green500.color

    /// 라이트 화면 배경.
    static let dsBgLight = DSColorToken.gray50.color
    /// 다크 화면 배경(영상·로딩).
    static let dsBgDark = DSColorToken.black800.color
    /// 다크 화면 위 표면(카드 등).
    static let dsSurfaceDark = DSColorToken.gray900.color

    /// 기본 텍스트(라이트 위).
    static let dsTextPrimary = DSColorToken.gray900.color
    /// 다크 위 기본 텍스트.
    static let dsTextOnDark = DSColorToken.white.color
    /// 보조 텍스트.
    static let dsTextSecondary = DSColorToken.gray500.color
    /// 3차 텍스트·비활성.
    static let dsTextTertiary = DSColorToken.gray400.color

    /// 구분선.
    static let dsSeparator = DSColorToken.gray100.color
    /// 긍정 상태.
    static let dsPositive = DSColorToken.positive500.color
    /// 오류·부정 상태.
    static let dsError = DSColorToken.error500.color
}
