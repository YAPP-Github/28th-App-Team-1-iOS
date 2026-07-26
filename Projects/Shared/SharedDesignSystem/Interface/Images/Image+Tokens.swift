//
//  Image+Tokens.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

/// Tuist 가 Assets.xcassets 를 스캔해 만드는 접근자(`Derived/Sources/TuistAssets+…`)의 축약.
/// 에셋을 지우거나 이름을 바꾸면 여기서 **컴파일이 깨진다** — 문자열 로드였을 땐 런타임에야 드러났다.
private typealias Asset = SharedDesignSystemInterfaceAsset

// @lat: [[architecture#디자인 시스템]]
// 이미지 토큰 — Color 팔레트와 같은 패밀리 enum 접근 (Ic = 아이콘, Img = 일러스트·이미지).
// 생성 접근자는 파일명을 기계 변환한 이름(icCancelMini)뿐이라 크기·틴트 여부를 알 수 없다 —
// 그 정보를 붙이는 게 이 층의 일이다.
public extension Image {

    /// 아이콘 — template 에셋은 `foregroundStyle` 로 틴트, 원본색 에셋은 그대로 렌더 (각 토큰 주석 참조).
    enum Ic {
        /// 닫기(X) · 24pt · template — foregroundStyle 로 틴트 (Figma hugeicons:cancel-01).
        public static var close: Image { Asset.Assets.icClose.swiftUIImage }
        /// 입력 클리어 · 24pt · 원본색 (회색 원 + 검정 X, Figma cancel mini/24px/grey default).
        public static var cancelMini: Image { Asset.Assets.icCancelMini.swiftUIImage }
        /// 작은 X · 20pt · template — 파일 행 제거 버튼 (Figma proicons:cancel).
        public static var cancelSmall: Image { Asset.Assets.icCancelSmall.swiftUIImage }
        /// 안내 · 16pt · 원본색 (Figma info/16px/disabled).
        public static var info: Image { Asset.Assets.icInfo.swiftUIImage }
        /// 에러 · 16pt · 원본색 (빨간 원 + 흰 느낌표, Figma issue/16px/error).
        public static var error: Image { Asset.Assets.icError.swiftUIImage }
        /// 성공 · 16pt · 원본색 (초록 원 + 흰 체크, Figma success/16px/green).
        public static var success: Image { Asset.Assets.icSuccess.swiftUIImage }
        /// 업로드 화살표 · 20×24 · template — 검은 원 배경은 코드에서 그린다.
        public static var upload: Image { Asset.Assets.icUpload.swiftUIImage }
    }

    /// 일러스트·이미지 — 원본색 렌더.
    enum Img {
        /// 툴팁 꼬리 · 97×11 · 원본색(#1A1B1F) — 말풍선 하단에 이어붙인다.
        public static var tooltipTail: Image { Asset.Assets.imgTooltipTail.swiftUIImage }
    }
}
