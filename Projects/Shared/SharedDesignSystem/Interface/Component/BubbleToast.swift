//
//  BubbleToast.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 짧은 상태 안내 말풍선 — Figma «BubbleField»(node 2555:7543) 1:1.
/// 표출 위치·표출/해제 타이밍은 호출부 책임(예: CTA 위 10pt, 2초 자동 해제).
///
/// 두 변형은 같은 Figma 컴포넌트의 status 차이다:
/// - `.toast`(status=none) — 폭 274 고정 · b800 배경 · py12 · 꼬리 없음.
/// - `.tooltip`(status5) — 내용 폭 · gray900 배경 · py8 · 아래로 꼬리. 특정 요소를 가리킬 때.
public struct BubbleToast: View {
    public enum Style: Sendable {
        case toast
        case tooltip
    }

    private let message: String
    private let style: Style

    public init(_ message: String, style: Style = .toast) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        VStack(spacing: 0) {
            bubble
            if style == .tooltip {
                Image.Img.tooltipTailDark
                    .resizable()
                    .frame(width: 97, height: 11)
            }
        }
    }

    private var bubble: some View {
        Text(message)
            .dsTypography(.body5)
            .foregroundStyle(Color.BlackWhite.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: style == .toast ? .infinity : nil)
            .padding(.horizontal, .ds(.p14))
            .padding(.vertical, style == .toast ? .ds(.p12) : .ds(.p8))
            .background(style == .toast ? Color.HilitBlack.b800 : Color.GrayScale.g900)
            // Figma BubbleField status=none 은 고정 폭 274, status5 는 내용 폭.
            .frame(width: style == .toast ? 274 : nil)
    }
}

#Preview("토스트") {
    BubbleToast("모든 평가가 끝났어요!")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.BlackWhite.white)
}

#Preview("툴팁") {
    BubbleToast("영상 해상도가 낮아 분석율이 떨어질 수 있어요.", style: .tooltip)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.HilitBlack.b900)
}
