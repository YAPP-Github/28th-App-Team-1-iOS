//
//  Color+Load.swift
//  DesignSystemKit
//
//  모든 컬러 토큰이 거치는 단일 seam (GmoneyTrans_Japan Color+.swift 방식).
//

import SwiftUI
import UIKit

public extension Color {
    /// 디자인 시스템 번들(`Colors.xcassets`)의 컬러셋을 이름으로 로드한다.
    ///
    /// 번들 해석을 한 곳에 모으고, 개발 빌드에선 존재하지 않는 이름을 `assert` 로 즉시 잡는다
    /// (릴리즈 빌드에선 제거 — 누락 시 무음 fallback). SwiftUI `Color` 에는 존재 검증 API 가 없어
    /// `UIColor` 로 우회 확인한다.
    static func load(_ name: String) -> Color {
        assert(
            UIColor(named: name, in: .designSystem, compatibleWith: nil) != nil,
            "\(name) 컬러 로드 실패 — DesignSystemKit/Resources/Colors.xcassets 확인"
        )
        return Color(name, bundle: .designSystem)
    }
}
