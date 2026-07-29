//
//  TagButtonStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

// Figma: «ButtonTag» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=1941-6762

import SwiftUI

/// 태그 토글 — h29 · px12/py4 · 직각 · hug. 다크 판 위 3상태이며 불리언 토글이 아니다:
/// 선택되면 weight 까지 바뀌고(body3→body1), 완료는 **레이어 전체 20% 투명**으로 가라앉는다.
/// 상태는 리듀서가 들고 있으므로 스타일 파라미터로 명시해 받는다.
public struct TagButtonStyle: ButtonStyle {
    /// Figma `status` 축.
    public enum Phase: Sendable, CaseIterable {
        /// 미선택 — 투명 배경 + 흰 글자
        case `default`
        /// 선택 — 그린 배경 + Bold
        case selected
        /// 완료 — 전체 20% 투명 (비활성 룩)
        case completed
    }

    private let phase: Phase

    public init(phase: Phase = .default) {
        self.phase = phase
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(phase == .selected ? .body1 : .body3)
            .padding(.horizontal, .ds(.p12))
            .padding(.vertical, .ds(.p4))
            .foregroundStyle(foreground)
            .background(background)
            .contentShape(Rectangle())
            // @ds(color): opacity 20% — completed 상태의 레이어 전체 투명 (토큰 없음, Figma 실측)
            .opacity(phase == .completed ? 0.2 : 1)
    }

    private var foreground: Color {
        switch phase {
        case .default, .completed: Color.BlackWhite.white
        case .selected: Color.HilitGreen.g800
        }
    }

    private var background: Color {
        switch phase {
        case .default: .clear
        case .selected: Color.HilitGreen.g500
        case .completed: Color.HilitBlack.b800
        }
    }
}

public extension ButtonStyle where Self == TagButtonStyle {
    /// 태그 토글 — 다크 판 전용.
    static func tag(_ phase: TagButtonStyle.Phase) -> Self {
        TagButtonStyle(phase: phase)
    }
}

#Preview("tag 3상태") {
    HStack(spacing: .ds(.p8)) {
        Button("지인피드백") {}.buttonStyle(.tag(.default))
        Button("지인피드백") {}.buttonStyle(.tag(.selected))
        Button("지인피드백") {}.buttonStyle(.tag(.completed))
    }
    .padding(.ds(.p20))
    .background(Color.HilitBlack.b900)
}
