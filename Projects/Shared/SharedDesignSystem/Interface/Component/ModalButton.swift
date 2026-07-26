//
//  ModalButton.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 모달 확인 버튼 설탕 — 본체는 ``ButtonLarge``(`.modal`)다.
/// `PrimaryButton`(하단 도킹, 배경이 안전영역까지 번짐)과 달리 배경 번짐이 없어 카드·아일랜드 안에 넣는다.
/// 2버튼 모달은 `ButtonLarge(.modal, tone:)` 슬롯 형태를 직접 쓴다.
public struct ModalButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        ButtonLarge(title, .modal, action: action)
    }
}

#Preview {
    VStack(spacing: 0) {
        Color.BlackWhite.white.frame(height: 120)   // 카드 본문 시뮬레이션
        ModalButton("다음") {}
        ButtonLarge(.modal, tone: .twoColor) {
            Button("취소") {}
        } trailing: {
            Button("삭제") {}
        }
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b800.opacity(0.4)) // 딤 위 아일랜드 시뮬레이션
}
