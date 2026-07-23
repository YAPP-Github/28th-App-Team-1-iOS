//
//  Image+Tokens.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

// @lat: [[architecture#디자인 시스템]]
// 이미지 토큰 — Color 팔레트와 같은 패밀리 enum 접근 (Ic = 아이콘, Img = 일러스트·이미지).
// 에셋명은 Ic*/Img* 프리픽스, 로드는 Image.load 단일 seam.
public extension Image {

    /// 아이콘 — template 에셋은 `foregroundStyle` 로 틴트, 원본색 에셋은 그대로 렌더 (각 토큰 주석 참조).
    enum Ic {
        /// 닫기(X) · 24pt · template — foregroundStyle 로 틴트 (Figma hugeicons:cancel-01).
        public static var close: Image { .load("IcClose") }
        /// 입력 클리어 · 24pt · 원본색 (회색 원 + 검정 X, Figma cancel mini/24px/grey default).
        public static var cancelMini: Image { .load("IcCancelMini") }
        /// 작은 X · 20pt · template — 파일 행 제거 버튼 (Figma proicons:cancel).
        public static var cancelSmall: Image { .load("IcCancelSmall") }
        /// 안내 · 16pt · 원본색 (Figma info/16px/disabled).
        public static var info: Image { .load("IcInfo") }
        /// 에러 · 16pt · 원본색 (빨간 원 + 흰 느낌표, Figma issue/16px/error).
        public static var error: Image { .load("IcError") }
        /// 성공 · 16pt · 원본색 (초록 원 + 흰 체크, Figma success/16px/green).
        public static var success: Image { .load("IcSuccess") }
        /// 업로드 화살표 · 20×24 · template — 검은 원 배경은 코드에서 그린다.
        public static var upload: Image { .load("IcUpload") }
    }

    /// 일러스트·이미지 — 원본색 렌더.
    enum Img {
        /// 툴팁 꼬리 · 97×11 · 원본색(#1A1B1F) — 말풍선 하단에 이어붙인다.
        public static var tooltipTail: Image { .load("ImgTooltipTail") }
    }
}
