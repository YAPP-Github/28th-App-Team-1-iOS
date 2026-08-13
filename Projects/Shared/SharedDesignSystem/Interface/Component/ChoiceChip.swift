//
//  ChoiceChip.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/22.
//

import SwiftUI

/// 선택 상태를 갖는 척도 칩 — HStack 에 나란히 놓아 N지선다를 구성한다.
/// Figma «button-medium»(node 2150:7297·2555:7563·2192:5191) 1:1.
///
/// 외형은 `.medium(_:layout:)` 이 그리고, 이 타입은 **«선택 상태 → 어떤 톤»** 규칙만 갖는다 —
/// 미선택은 회색, 선택은 극에 따라 긍정(blue)·부정(red). 선택 시 SemiBold 로 굵어지는 것도 톤에
/// 딸려 있어 따로 지정하지 않는다. 규칙을 호출부에 흩뿌리면 척도 화면마다 같은 삼항이 반복된다.
public struct ChoiceChip: View {
    /// 칩이 속한 극 — 긍정 선택지 / 부정 선택지.
    public enum Tone: Sendable {
        case positive
        case negative
    }

    private let label: String
    private let isSelected: Bool
    private let tone: Tone
    private let layout: MediumButtonStyle.Layout
    private let action: () -> Void

    /// - Parameter layout: 기본 `.fill`(주어진 폭을 N등분). 라벨이 길어 한 줄에 다 안 들어가고
    ///   가로 스크롤로 흘리는 척도(지인 피드백 5축)는 `.hug` 로 라벨 폭을 지킨다.
    public init(
        _ label: String,
        isSelected: Bool,
        tone: Tone,
        layout: MediumButtonStyle.Layout = .fill,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isSelected = isSelected
        self.tone = tone
        self.layout = layout
        self.action = action
    }

    public var body: some View {
        Button(label, action: action)
            .buttonStyle(.medium(mediumTone, layout: layout))
    }

    private var mediumTone: MediumButtonStyle.Tone {
        guard isSelected else { return .gray }
        return tone == .positive ? .blue : .red
    }
}

#Preview {
    VStack(spacing: .ds(.p20)) {
        HStack(spacing: .ds(.p8)) {
            ChoiceChip("잘 맞춤", isSelected: false, tone: .positive) {}
            ChoiceChip("꽤 맞춤", isSelected: true, tone: .positive) {}
            ChoiceChip("가끔 피함", isSelected: false, tone: .negative) {}
            ChoiceChip("자주 피함", isSelected: false, tone: .negative) {}
        }
        HStack(spacing: .ds(.p8)) {
            ChoiceChip("아주 긴 라벨도 한 줄", isSelected: false, tone: .positive) {}
            ChoiceChip("축소되어 들어간다", isSelected: true, tone: .negative) {}
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
