//
//  ModalButton.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 모달/오버레이 내부용 풀폭 CTA — Figma «button-large/modal»(node 2302:5985) 1:1.
/// b800 배경 · sub7(SemiBold 18) 흰 텍스트 · py16 대칭(높이 55) · 모서리 0.
/// `PrimaryButton`(하단 도킹 전용 — 배경이 키보드·세이프에어리어까지 번짐)과 달리
/// 배경 번짐이 없어 카드·아일랜드 안에 넣을 수 있다.
public struct ModalButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .ds(.p16))
                .background(Color.HilitBlack.b800)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        Color.BlackWhite.white.frame(height: 120)   // 카드 본문 시뮬레이션
        ModalButton("다음") {}
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b800.opacity(0.4)) // 딤 위 아일랜드 시뮬레이션
}
