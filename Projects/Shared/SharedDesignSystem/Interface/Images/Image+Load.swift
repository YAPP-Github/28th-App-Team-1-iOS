//
//  Image+Load.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

extension Image {
    /// 이미지 에셋(Assets.xcassets) 로드 단일 seam — `Color.load` 와 동일한 규약 (`.claude/design.md` 「에셋 로드 규칙」).
    /// 번들 해석을 일원화하고, 개발 빌드에선 이름 오타를 `assert` 로 조기 검출한다.
    static func load(_ name: String) -> Image {
        #if DEBUG && canImport(UIKit)
        assert(
            UIImage(named: name, in: .module, compatibleWith: nil) != nil,
            "SharedDesignSystem: 이미지 에셋 '\(name)' 을(를) Assets.xcassets 에서 찾을 수 없습니다."
        )
        #endif
        return Image(name, bundle: .module)
    }
}
