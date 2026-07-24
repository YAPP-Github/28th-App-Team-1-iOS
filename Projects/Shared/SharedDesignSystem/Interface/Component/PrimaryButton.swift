//
//  PrimaryButton.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/22.
//

import SwiftUI

/// 하단 공용 CTA(피드백 시작하기·다음·피드백 전송하기).
/// Figma `button-large`(node 2091:4488, status filled-1/filled-2) 1:1 —
/// 블랙(#1A1B1F = hilit black/800) 풀폭 바 · 흰 18pt SemiBold(sub7) · 모서리 0(풀블리드).
/// 비활성은 호출부가 `.disabled(...)` modifier 로 준다 — Figma color=disabled 변형
/// (gray50 배경 · gray300 텍스트, node 1941:3247)으로 그려진다. 로딩 중엔 `ProgressView`.
/// 하단 도킹 풀블리드 CTA — 배경 바가 하단 안전영역(홈 인디케이터)까지 번져 나간다.
public struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(Color.BlackWhite.white)
                } else {
                    Text(title).dsTypography(.sub7)
                }
            }
            // Figma 인스턴스 높이 55pt = pt22 + sub7 행간 23 + pb10 — 인스턴스에 붙은 padding-22/10/24 토큰 그대로.
            // minHeight 는 로딩(ProgressView) 상태에서도 바 높이 55 를 유지하기 위한 텍스트 행간 바닥.
            .frame(maxWidth: .infinity, minHeight: DSTypography.sub7.lineHeight)
            .padding(.top, .ds(.p22))
            .padding(.bottom, .ds(.p10))
            .padding(.horizontal, .ds(.p24))
            .foregroundStyle(isEnabled ? Color.BlackWhite.white : Color.Gray.g300)
            // Figma 실측: #1A1B1F(hilit black/800) 풀블리드 바 · 모서리 0 (브리프의 green/p12 기본값과 상이).
            // 배경만 하단 안전영역까지 확장 — 콘텐츠/탭 타깃(minHeight 52 프레임)은 안전영역 위에 그대로 남는다.
            .background(
                (isEnabled ? Color.HilitBlack.b800 : Color.Gray.g50)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton("피드백 시작하기") {}       // 기본
        PrimaryButton("전송 중", isLoading: true) {} // 로딩 → ProgressView
        PrimaryButton("비활성") {}.disabled(true)   // 비활성(호출부 modifier)
    }
    .padding()
}
