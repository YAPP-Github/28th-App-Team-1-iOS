//
//  DarkChip.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 다크 화면의 선택형 칩 — Figma «button-mini/dark/filled»(green-selected / black-default).
/// 질문 탭(16pt)과 지인 이름 탭(14pt)이 같은 컴포넌트의 글자 크기 차이다.
///
/// DS 의 `MiniButton` 은 라이트 배경 + 아이콘 보조 액션용이라 여기 쓰지 않는다.
/// 리포트 밖에 두 번째 사용처가 생기면 그때 Shared 로 승격한다(승격 규칙 ②).
struct DarkChip: View {
    enum Size {
        /// 질문 탭 — 16pt.
        case regular
        /// 지인 이름 탭 — 14pt.
        case small

        var selectedTypography: DSTypography {
            switch self {
            case .regular: .body2
            case .small: .body5
            }
        }

        var defaultTypography: DSTypography {
            switch self {
            // 미선택은 한 단계 가벼운 웨이트 — Figma 는 선택만 SemiBold 로 올린다.
            case .regular: .body3
            case .small: .body5
            }
        }
    }

    let title: String
    let isSelected: Bool
    var size: Size = .regular
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .dsTypography(isSelected ? size.selectedTypography : size.defaultTypography)
                .foregroundStyle(isSelected ? Color.HilitGreen.g800 : Color.Gray.g300)
                .padding(.horizontal, .ds(.p12))
                .padding(.vertical, .ds(.p8))
                .background(isSelected ? Color.HilitGreen.g500 : Color.Gray.g900)
        }
        .buttonStyle(.plain)
    }
}

#Preview("다크 칩") {
    VStack(alignment: .leading, spacing: .ds(.p12)) {
        HStack(spacing: .ds(.p10)) {
            DarkChip(title: "질문 1-1", isSelected: true) {}
            DarkChip(title: "질문 1-2", isSelected: false) {}
        }
        HStack(spacing: .ds(.p8)) {
            DarkChip(title: "허자연", isSelected: true, size: .small) {}
            DarkChip(title: "박민주", isSelected: false, size: .small) {}
        }
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
