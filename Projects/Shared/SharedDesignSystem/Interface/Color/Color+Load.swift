//
//  Color+Load.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// 색상 에셋(Colors.xcassets) 로드 단일 seam — `.claude/design.md` 「에셋 로드 규칙」.
    /// 에셋명은 HEX(`Color636777`). 번들 해석을 일원화하고, 개발 빌드에선 이름 오타를 `assert` 로 조기 검출한다.
    /// 폰트의 `Pretendard.registerOnce` 와 같은 역할(리소스 접근 단일 진입점).
    static func load(_ name: String) -> Color {
        #if DEBUG && canImport(UIKit)
        assert(
            UIColor(named: name, in: .module, compatibleWith: nil) != nil,
            "SharedDesignSystem: 색상 에셋 '\(name)' 을(를) Colors.xcassets 에서 찾을 수 없습니다."
        )
        #endif
        return Color(name, bundle: .module)
    }
}
