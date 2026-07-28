//
//  CatalogSupport.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 카탈로그 페이지 껍데기 — 스크롤 + 여백 + 제목. 여백은 화면 좌우 기본값 p20.
struct CatalogPage<Content: View>: View {
    private let title: String
    private let background: Color
    private let content: Content

    init(_ title: String, background: Color = Color.BlackWhite.white, @ViewBuilder content: () -> Content) {
        self.title = title
        self.background = background
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .ds(.p24)) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.ds(.p20))
        }
        .background(background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 견본 한 덩어리 — 위에 토큰/API 이름표, 아래 실물.
struct CatalogGroup<Content: View>: View {
    private let label: String
    private let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            Text(label)
                .dsTypography(.body9)
                .foregroundStyle(Color.GrayScale.g400)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
