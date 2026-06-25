//
//  Bundle+DesignSystem.swift
//  DesignSystemKit
//
//  GmoneyTrans_Japan 의 R+Bundle 방식을 SwiftUI 전용으로 단순화 — 리소스 번들 해석을 한 곳에 모은다.
//

import Foundation

public extension Bundle {
    /// DesignSystemKit 의 에셋(`Colors.xcassets` · `Assets.xcassets`)이 담긴 리소스 번들.
    ///
    /// Tuist 가 리소스 보유 타겟에 합성하는 `.module` 을 가리킨다.
    /// 컬러·이미지 로드는 항상 이 번들을 통한다 (``SwiftUI/Color/load(_:)`` · ``SwiftUI/Image/load(_:)``).
    static var designSystem: Bundle { .module }
}
