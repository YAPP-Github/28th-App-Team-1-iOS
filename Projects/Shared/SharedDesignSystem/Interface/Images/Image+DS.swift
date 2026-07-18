//
//  Image+DS.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/07/18.
//

import SwiftUI
import UIKit

// @lat: [[architecture#디자인 시스템]]
public extension Image {
    /// 이미지 에셋 로드 단일 seam — Color.load 와 동일한 규약 (번들 일원화 + 개발 빌드 assert).
    static func load(_ name: String) -> Image {
        assert(
            UIImage(named: name, in: .module, compatibleWith: nil) != nil,
            "이미지 에셋 누락: \(name)"
        )
        return Image(name, bundle: .module)
    }

    /// 이미지 토큰 네임스페이스 — 늘어나면 Ic/Img 중첩 enum 으로 묶는다.
    enum DS {
        /// 닫기(X) · 24pt · template — foregroundStyle 로 틴트 (Figma hugeicons:cancel-01).
        public static let icClose = Image.load("IcClose")
    }
}
