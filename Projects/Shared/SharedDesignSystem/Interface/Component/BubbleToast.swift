//
//  BubbleToast.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 짧은 상태 안내 토스트 — Figma «BubbleField»(status=none, node 2555:7543) 1:1.
/// 폭 274 고정 · b800 배경 · 직각 모서리 · body5(SemiBold 14) 흰 텍스트 중앙정렬 · px14/py12.
/// 표출 위치·표출/해제 타이밍은 호출부 책임(예: CTA 위 10pt, 2초 자동 해제).
public struct BubbleToast: View {
    private let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .dsTypography(.body5)
            .foregroundStyle(Color.BlackWhite.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .ds(.p14))
            .padding(.vertical, .ds(.p12))
            .background(Color.HilitBlack.b800)
            // Figma BubbleField 고정 폭 274.
            .frame(width: 274)
    }
}

#Preview {
    BubbleToast("모든 평가가 끝났어요!")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.BlackWhite.white)
}
