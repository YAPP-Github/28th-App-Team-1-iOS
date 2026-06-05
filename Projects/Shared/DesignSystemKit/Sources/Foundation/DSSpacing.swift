//
//  DSSpacing.swift
//  DesignSystemKit
//
//  Created by EunseoKim on 5/26/26.
//

import CoreFoundation

/// 디자인 시스템 spacing 토큰.
///
/// 화면 margin·padding·gap 등 모든 거리 값을 토큰으로만 표현. 직접 숫자(8, 12, 16) 금지.
public extension CGFloat {
    /// 4
    static let dsXS: CGFloat = 4
    /// 8
    static let dsS: CGFloat = 8
    /// 12
    static let dsM: CGFloat = 12
    /// 16
    static let dsL: CGFloat = 16
    /// 24
    static let dsXL: CGFloat = 24
    /// 32
    static let dsXXL: CGFloat = 32
}
