//
//  CatalogColorView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 팔레트 23색 — 패밀리 enum 은 `static var` 묶음이라 순회가 안 돼 손으로 열거한다.
/// 색이 늘면 이 목록에 한 줄 추가한다(HEX 는 에셋명에만 있고 공개 API 로 못 읽어 이름만 보여준다).
struct CatalogColorView: View {
    private typealias Swatch = (name: String, color: Color)

    private let families: [(family: String, swatches: [Swatch])] = [
        ("HilitBlack", [
            ("b800", Color.HilitBlack.b800),
            ("b900", Color.HilitBlack.b900)
        ]),
        ("HilitGreen", [
            ("g500", Color.HilitGreen.g500),
            ("g600", Color.HilitGreen.g600),
            ("g800", Color.HilitGreen.g800)
        ]),
        ("Error", [
            ("e200", Color.Error.e200),
            ("e300", Color.Error.e300),
            ("e400", Color.Error.e400),
            ("e500", Color.Error.e500)
        ]),
        ("Positive", [
            ("p200", Color.Positive.p200),
            ("p500", Color.Positive.p500),
            ("p800", Color.Positive.p800)
        ]),
        ("GrayScale", [
            ("g50", Color.GrayScale.g50),
            ("g100", Color.GrayScale.g100),
            ("g200", Color.GrayScale.g200),
            ("g300", Color.GrayScale.g300),
            ("g400", Color.GrayScale.g400),
            ("g500", Color.GrayScale.g500),
            ("g600", Color.GrayScale.g600),
            ("g700", Color.GrayScale.g700),
            ("g800", Color.GrayScale.g800),
            ("g900", Color.GrayScale.g900)
        ]),
        ("BlackWhite", [
            ("white", Color.BlackWhite.white)
        ])
    ]

    var body: some View {
        CatalogPage("색상") {
            ForEach(families, id: \.family) { family in
                CatalogGroup("Color.\(family.family)") {
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: .ds(.p8)), count: 4), spacing: .ds(.p8)) {
                        ForEach(family.swatches, id: \.name) { swatch in
                            VStack(spacing: .ds(.p4)) {
                                Rectangle()
                                    .fill(swatch.color)
                                    .frame(height: 48)
                                    .overlay {
                                        Rectangle()
                                            .strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.small))
                                    }
                                Text(swatch.name)
                                    .dsTypography(.body9)
                                    .foregroundStyle(Color.GrayScale.g700)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CatalogColorView() }
}
