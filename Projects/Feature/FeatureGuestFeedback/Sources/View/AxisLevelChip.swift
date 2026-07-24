//
//  AxisLevelChip.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import SharedDesignSystemInterface
import SwiftUI

/// 4단계 척도 칩 1개 — 평가 화면 흰 카드 위에 놓인다.
/// Figma «button-medium»(node 2150:7297·2555:7563·2192:5191) 1:1 — 직사각형(radius 0),
/// 기본=흰 필 + gray/100 테두리 + gray/700 텍스트,
/// 선택·긍정=positive/200 필 + positive/500 테두리 + positive/800 SemiBold,
/// 선택·부정=error/200 필 + error/500 테두리·텍스트 SemiBold.
struct AxisLevelChip: View {
    /// 칩이 속한 극 — 1~2단계(좋았어요 쪽)=positive, 3~4단계(아쉬웠어요 쪽)=negative.
    enum Tone {
        case positive
        case negative
    }

    let label: String
    let isSelected: Bool
    let tone: Tone
    let action: () -> Void

    init(_ label: String, isSelected: Bool, tone: Tone, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.tone = tone
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .dsTypography(isSelected ? .body2 : .body3)  // 선택 SemiBold16(.body2) / 기본 Medium16(.body3)
                .foregroundStyle(text)
                // Figma «button-medium»은 flex-1 셀을 채우고 라벨을 한 줄(whitespace-nowrap) 가운데 정렬한다.
                // 4개 등폭 셀(≈77pt/375화면)에선 내부 가로 패딩을 두면 라벨 폭이 남지 않아 밀려/줄바꿈된다 →
                // maxWidth:.infinity 로만 폭을 잡고, 긴 카피(«조금 아쉬움» 등 잠정 문구)가
                // 한 줄이 넘칠 때만 축소해 한 줄·가운데를 유지한다.
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .ds(.p12))
                .background(fill)
                .overlay(Rectangle().stroke(border, lineWidth: .ds(.medium)))
        }
        .buttonStyle(.plain)
    }

    private var fill: Color {
        guard isSelected else { return Color.BlackWhite.white }
        return tone == .positive ? Color.Positive.p200 : Color.Error.e200
    }

    private var border: Color {
        guard isSelected else { return Color.Gray.g100 }
        return tone == .positive ? Color.Positive.p500 : Color.Error.e500
    }

    private var text: Color {
        guard isSelected else { return Color.Gray.g700 }
        return tone == .positive ? Color.Positive.p800 : Color.Error.e500
    }
}

#Preview {
    VStack(spacing: .ds(.p20)) {
        HStack(spacing: .ds(.p8)) {
            AxisLevelChip("잘 맞춤", isSelected: false, tone: .positive, action: {})
            AxisLevelChip("꽤 맞춤", isSelected: true, tone: .positive, action: {})
            AxisLevelChip("가끔 피함", isSelected: false, tone: .negative, action: {})
            AxisLevelChip("자주 피함", isSelected: false, tone: .negative, action: {})
        }
        HStack(spacing: .ds(.p8)) {
            AxisLevelChip("좋았어요", isSelected: false, tone: .positive, action: {})
            AxisLevelChip("괜찮았어요", isSelected: false, tone: .positive, action: {})
            AxisLevelChip("조금 아쉬움", isSelected: true, tone: .negative, action: {})
            AxisLevelChip("많이 아쉬움", isSelected: false, tone: .negative, action: {})
        }
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.BlackWhite.white)  // 평가 카드(흰 배경) 시뮬레이션
}
