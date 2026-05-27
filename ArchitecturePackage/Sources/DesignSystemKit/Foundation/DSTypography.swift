//
//  DSTypography.swift
//  DesignSystemKit
//
//  Created by EunseoKim on 5/26/26.
//

import SwiftUI

/// 디자인 시스템 타이포그래피 토큰.
///
/// 폰트 크기·굵기를 한 곳에 모아 둔다. 화면 단위에서 `Font.dsBody` 식으로만 참조.
/// Apple HIG 의 의미 스케일에 가깝게 정렬되어 있으며, 새 화면을 만들 때는
/// 기존 토큰을 먼저 활용한 뒤 부족하면 여기서 추가한다.
public extension Font {
    /// 화면 진입 시 보이는 큰 타이틀. (34 / bold)
    static let dsLargeTitle = Font.system(size: 34, weight: .bold)

    /// 화면 타이틀. 보통 NavigationStack 의 `.large` 타이틀 보조용. (28 / bold)
    static let dsTitle = Font.system(size: 28, weight: .bold)

    /// 섹션 타이틀·서브 헤더. (22 / semibold)
    static let dsTitle2 = Font.system(size: 22, weight: .semibold)

    /// 섹션 헤드라인. (17 / semibold)
    static let dsHeadline = Font.system(size: 17, weight: .semibold)

    /// 본문 강조 — 같은 크기 본문 중 강조 텍스트. (15 / semibold)
    static let dsBodyBold = Font.system(size: 15, weight: .semibold)

    /// 본문 텍스트. (15 / regular)
    static let dsBody = Font.system(size: 15, weight: .regular)

    /// 본문보다 한 단계 작은 부가 설명·짧은 인용. (13 / regular)
    static let dsCallout = Font.system(size: 13, weight: .regular)

    /// 보조 텍스트·캡션. (12 / regular)
    static let dsCaption = Font.system(size: 12, weight: .regular)
}
