//
//  CatalogTypographyView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 타이포 토큰 25종 — `DSTypography.allCases` 를 그대로 돈다(직접 열거하지 않아 토큰이 늘면 자동 반영).
/// 크기·웨이트 수치는 `internal` 이라 여기서 못 읽는다 — 표는 `.claude/design/typography.md`.
struct CatalogTypographyView: View {
    private let sample = "힐릿 디자인 AaBb 123"

    var body: some View {
        CatalogPage("타이포그래피") {
            ForEach(DSTypography.allCases, id: \.self) { typography in
                CatalogGroup(typography.rawValue) {
                    Text(sample)
                        .dsTypography(typography)
                        .foregroundStyle(Color.GrayScale.g900)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CatalogTypographyView() }
}
