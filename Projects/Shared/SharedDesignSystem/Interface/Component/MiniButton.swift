//
//  MiniButton.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 섹션 우측 보조 액션용 소형 버튼 — Figma «button-mini/with-icon»(node 2227:4448) 1:1.
/// gray/100 배경 · b800 아이콘+텍스트(body5) · px10/py8 · 모서리 6pt(대응 radius 토큰 없어 리터럴).
public struct MiniButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: .ds(.p4)) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.ds(.body8))
                }
                Text(title)
                    .dsTypography(.body5)
            }
            .foregroundStyle(Color.HilitBlack.b800)
            .padding(.horizontal, .ds(.p10))
            .padding(.vertical, .ds(.p8))
            .background(Color.Gray.g100, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: .ds(.p12)) {
        MiniButton("영상 다시보기", systemImage: "play.rectangle.fill") {}
        MiniButton("전체 보기") {}
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
