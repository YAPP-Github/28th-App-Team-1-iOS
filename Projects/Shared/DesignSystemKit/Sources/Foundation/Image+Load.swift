//
//  Image+Load.swift
//  DesignSystemKit
//
//  모든 이미지 토큰이 거치는 단일 seam (GmoneyTrans_Japan Image+.swift 방식).
//

import SwiftUI
import UIKit

public extension Image {
    /// 디자인 시스템 번들(`Assets.xcassets`)의 이미지셋을 이름으로 로드한다.
    ///
    /// ``SwiftUI/Color/load(_:)`` 과 동일한 규칙 — 번들 해석 일원화 + 개발 빌드 `assert` 로 오타 검출.
    static func load(_ name: String) -> Image {
        assert(
            UIImage(named: name, in: .designSystem, compatibleWith: nil) != nil,
            "\(name) 이미지 로드 실패 — DesignSystemKit/Resources/Assets.xcassets 확인"
        )
        return Image(name, bundle: .designSystem)
    }
}
