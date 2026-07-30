//
//  InterviewTimerChip.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import SharedDesignSystemInterface
import SwiftUI

/// 세션 상단 중앙 시간 칩 — Figma «highlighted-text» 타이머 변형(2529:9139 · 카운트다운 2537:9529).
/// `Parallelogram` 배경에 스톱워치 아이콘(16) + body2 텍스트. `HighlightedText` 와 같은
/// px8 규약이지만 아이콘이 들어가 별도 조립한다.
/// - elapsed: gray-50 배경 · gray-500 «m:ss»
/// - countdown: error-200 배경 · error-500 «N초»
struct InterviewTimerChip: View {
    enum Variant: Equatable {
        /// 경과 시간 (초)
        case elapsed(seconds: Int)
        /// 종료 카운트다운 (남은 초)
        case countdown(remaining: Int)
    }

    var variant: Variant

    var body: some View {
        HStack(spacing: 2) {
            // @ds(icon: timer/error16) — 카운트다운 시안의 빨간 스톱워치가 DS 에 없다. 아이콘은 색이
            // 에셋에 구워져 있어 틴트가 불가(design/image.md)라, 회색 변형 하나로 두 상태를 함께 쓴다.
            Image.Timer.disabled16
            Text(label)
                .dsTypography(.body2)
                .foregroundStyle(foreground)
        }
        .padding(.horizontal, .ds(.p8))
        .background(background, in: Parallelogram())
    }

    private var label: String {
        switch variant {
        case let .elapsed(seconds):
            "\(seconds / 60):" + String(format: "%02d", seconds % 60)
        case let .countdown(remaining):
            "\(remaining)초"
        }
    }

    private var foreground: Color {
        switch variant {
        case .elapsed: Color.GrayScale.g500
        case .countdown: Color.Error.e500
        }
    }

    private var background: Color {
        switch variant {
        case .elapsed: Color.GrayScale.g50
        case .countdown: Color.Error.e200
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        InterviewTimerChip(variant: .elapsed(seconds: 1))
        InterviewTimerChip(variant: .elapsed(seconds: 80))
        InterviewTimerChip(variant: .elapsed(seconds: 480))
        InterviewTimerChip(variant: .countdown(remaining: 10))
    }
    .padding()
    .background(Color.GrayScale.g900)
}
