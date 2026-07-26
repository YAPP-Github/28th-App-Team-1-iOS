//
//  MiniButton.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 섹션 우측 보조 액션용 소형 버튼 설탕 — 본체는 `.buttonStyle(.mini(_:))` 다.
/// Figma «button-mini/with-icon»(node 2227:4441): gray/100 배경 · b800 body5 · px8/py8 · gap8 · 모서리 0.
/// 다른 색·다크 판·복잡한 라벨이 필요하면 `Button { … }.buttonStyle(.mini(...))` 를 직접 쓴다.
public struct MiniButton: View {
    private let title: String
    private let icon: Image?
    private let action: () -> Void

    /// - Parameter icon: DS 아이콘 토큰(예: `Image.Video.default16`). 색은 에셋에 구워져 있어 틴트하지 않는다.
    public init(_ title: String, icon: Image? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: .ds(.p8)) {
                if let icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text(title)
            }
        }
        .buttonStyle(.mini(.gray, layout: icon == nil ? .textOnly : .withIcon))
    }
}

#Preview {
    VStack(spacing: .ds(.p12)) {
        MiniButton("영상 다시보기", icon: Image.Video.default16) {}
        MiniButton("전체 보기") {}
        MiniButton("비활성") {}.disabled(true)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
