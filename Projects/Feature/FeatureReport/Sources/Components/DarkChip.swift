//
//  DarkChip.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 상세 리포트 질문 탭 칩 — Figma «button-mini/dark/filled»(green-selected / black-default)의 16pt 인스턴스.
///
/// DS `.mini` 는 body5(14pt) 고정이라 이 16pt 변형을 못 그린다 — 지인 이름 탭(14pt)은 `.mini` 를
/// 그대로 쓰고, 질문 탭만 이 칩이 남는다. 색 조합은 `.mini` 다크 판과 동일.
/// @ds(component): mini 16pt 티어 없음 — DS 에 생기면 교체
struct DarkChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                // 미선택은 한 단계 가벼운 웨이트 — Figma 는 선택만 SemiBold 로 올린다.
                .dsTypography(isSelected ? .body2 : .body3)
                .foregroundStyle(isSelected ? Color.HilitGreen.g800 : Color.GrayScale.g300)
                .padding(.horizontal, .ds(.p12))
                .padding(.vertical, .ds(.p8))
                .background(isSelected ? Color.HilitGreen.g500 : Color.GrayScale.g900)
        }
        .buttonStyle(.plain)
    }
}

#Preview("질문 탭 칩") {
    HStack(spacing: .ds(.p10)) {
        DarkChip(title: "질문 1-1", isSelected: true) {}
        DarkChip(title: "질문 1-2", isSelected: false) {}
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
