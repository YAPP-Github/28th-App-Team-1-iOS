//
//  DSColor.swift
//  DesignSystemKit
//
//  Created by EunseoKim on 5/26/26.
//

import SwiftUI

/// 디자인 시스템 색상 토큰.
///
/// 호출처는 항상 토큰으로만 색을 참조한다. `Color.blue` 같은 하드코딩 금지.
///
/// ```swift
/// Text("Hello").foregroundStyle(Color.dsPrimary)
/// ```
public extension Color {
    /// 강조 색상. 버튼·링크·선택 상태에 사용.
    static let dsPrimary = Color("DSPrimary", bundle: .module)

    /// 기본 배경 색상. 라이트/다크 자동 대응.
    static let dsBackground = Color("DSBackground", bundle: .module)

    /// 본문 텍스트 색상.
    static let dsTextPrimary = Color.primary

    /// 보조 텍스트 색상.
    static let dsTextSecondary = Color.secondary
}
