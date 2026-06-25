//
//  DSImage.swift
//  DesignSystemKit
//
//  Created by EunseoKim on 6/25/26.
//

import SwiftUI

/// 디자인 시스템 이미지 토큰.
///
/// 호출처는 토큰으로만 이미지를 참조한다 — 문자열 이름을 직접 쓰지 않는다.
/// 에셋이 늘면 GmoneyTrans_Japan 처럼 카테고리별 중첩 enum(`Ic` · `Img` 등)으로 묶는다.
///
/// ```swift
/// Image.DS.placeholder
/// ```
public extension Image {
    enum DS {
        /// 범용 플레이스홀더 이미지.
        public static var placeholder: Image { .load("DSPlaceholder") }
    }
}
