//
//  DSTypography.swift
//  DesignSystemKit
//
//  Created by EunseoKim on 5/26/26.
//

import SwiftUI

/// 디자인 시스템 타이포그래피 토큰.
///
/// 폰트 크기·굵기·줄높이를 한 곳에 모아 둔다. 화면 단위에서 `Font.dsBody` 식으로만 참조.
public extension Font {
    /// 큰 제목 (화면 진입 시 보이는 큰 타이틀).
    static let dsLargeTitle = Font.system(size: 34, weight: .bold)

    /// 섹션 헤드라인.
    static let dsHeadline = Font.system(size: 17, weight: .semibold)

    /// 본문 텍스트.
    static let dsBody = Font.system(size: 15, weight: .regular)

    /// 보조 텍스트·캡션.
    static let dsCaption = Font.system(size: 12, weight: .regular)
}
