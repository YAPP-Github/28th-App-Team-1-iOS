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
        /// 입력 클리어 · 24pt · 원본색 (회색 원 + 검정 X, Figma cancel mini/24px/grey default).
        public static let icCancelMini = Image.load("IcCancelMini")
        /// 작은 X · 20pt · template — 파일 행 제거 버튼 (Figma proicons:cancel).
        public static let icCancelSmall = Image.load("IcCancelSmall")
        /// 안내 · 16pt · 원본색 (Figma info/16px/disabled).
        public static let icInfo = Image.load("IcInfo")
        /// 에러 · 16pt · 원본색 (빨간 원 + 흰 느낌표, Figma issue/16px/error).
        public static let icError = Image.load("IcError")
        /// 성공 · 16pt · 원본색 (초록 원 + 흰 체크, Figma success/16px/green).
        public static let icSuccess = Image.load("IcSuccess")
        /// 업로드 화살표 · 20×24 · template — 검은 원 배경은 코드에서 그린다.
        public static let icUpload = Image.load("IcUpload")
        /// 툴팁 꼬리 · 97×11 · 원본색(#1A1B1F) — 말풍선 하단에 이어붙인다.
        public static let imgTooltipTail = Image.load("ImgTooltipTail")
    }
}
