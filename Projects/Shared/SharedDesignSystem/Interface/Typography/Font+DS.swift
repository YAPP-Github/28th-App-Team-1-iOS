//
//  Font+DS.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/18.
//

import SwiftUI

public extension Font {
    /// 타이포 토큰 → SwiftUI Font. 행간·자간까지 스펙대로 적용하려면 `View.dsTypography(_:)` 를 쓴다.
    /// Figma 스펙(px)과의 1:1 재현을 위해 고정 사이즈 — Dynamic Type 은 미반영(도입 결정 시 relativeTo 로 전환).
    static func ds(_ typography: DSTypography) -> Font {
        _ = Pretendard.registerOnce
        return .custom(typography.weight.postScriptName, fixedSize: typography.size)
    }
}
