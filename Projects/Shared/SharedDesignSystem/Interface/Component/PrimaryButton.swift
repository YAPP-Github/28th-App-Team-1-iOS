//
//  PrimaryButton.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/22.
//

import SwiftUI

/// 하단 CTA 설탕 — 본체는 ``ButtonLarge``(`.bottom`)다.
/// 라벨이 텍스트 하나뿐인 가장 흔한 경우를 짧게 쓰라고 남긴 래퍼이고,
/// 테두리형·2버튼이 필요하면 `ButtonLarge` 를 직접 쓴다.
/// 비활성은 호출부 `.disabled(...)`, 로딩은 `isLoading`(내부에서 `.hilitButtonLoading` 으로 전달).
public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        ButtonLarge(title, .bottom, action: action)
            .hilitButtonLoading(isLoading)
    }
}

#Preview {
    VStack(spacing: .ds(.p12)) {
        PrimaryButton("피드백 시작하기") {}
        PrimaryButton("전송 중", isLoading: true) {}
        PrimaryButton("비활성") {}.disabled(true)
    }
    .background(Color.BlackWhite.white)
}
