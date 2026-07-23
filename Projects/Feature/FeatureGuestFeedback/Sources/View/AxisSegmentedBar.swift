//
//  AxisSegmentedBar.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import DomainFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI

/// 평가 화면 상단 태도 축 세그먼트 바 — 영상(다크) 배경 위에 얹힌다.
/// Figma «[4] 객관식» segment row(node 2150:7288) 1:1 —
/// 선택=green/500 필 + green/800 Bold, 완료=green/800 텍스트(필 없음), 미완료=흰 텍스트.
/// (완료-비활성 상태는 Figma 프레임에 별도 시안이 없어 브랜드 텍스트로 표현 — 설계 의도 반영.)
struct AxisSegmentedBar: View {
    let axes: [AttitudeAxis]
    let selected: AttitudeAxis?
    let completedCodes: Set<String>
    let onSelect: (AttitudeAxis) -> Void

    init(
        axes: [AttitudeAxis],
        selected: AttitudeAxis?,
        completedCodes: Set<String>,
        onSelect: @escaping (AttitudeAxis) -> Void
    ) {
        self.axes = axes
        self.selected = selected
        self.completedCodes = completedCodes
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(spacing: .ds(.p4)) {
            ForEach(axes) { axis in
                Button {
                    onSelect(axis)
                } label: {
                    Text(axis.displayName)
                        .dsTypography(isSelected(axis) ? .body1 : .body3)  // 선택 Bold16(.body1 — Figma Bold16 그대로) / 기본 Medium16(.body3)
                        .foregroundStyle(textColor(for: axis))
                        // 시안은 축명이 항상 한 줄 — 서버가 긴 이름을 줘도 줄바꿈 대신 축소로 흡수한다.
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, .ds(.p12))
                        .padding(.vertical, .ds(.p4))
                        .background(fillColor(for: axis))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p14))
    }

    private func isSelected(_ axis: AttitudeAxis) -> Bool {
        selected?.code == axis.code
    }

    /// 선택=green/800, 완료=green/800, 미완료=흰색(다크 위 기본 텍스트).
    private func textColor(for axis: AttitudeAxis) -> Color {
        if isSelected(axis) { return .dsBrand }
        if completedCodes.contains(axis.code) { return .dsBrand }
        return .dsTextOnDark
    }

    /// 선택 칩만 green/500 필. 나머지는 투명(영상 배경 노출).
    @ViewBuilder
    private func fillColor(for axis: AttitudeAxis) -> some View {
        if isSelected(axis) {
            // DS에 radius 토큰이 없어 리터럴 유지(Figma 필 코너 ≈ 6pt).
            RoundedRectangle(cornerRadius: 6).fill(Color.dsBrandSoft)
        } else {
            Color.clear
        }
    }
}

#Preview {
    let axes = [
        AttitudeAxis(code: "GAZE", displayName: "시선"),
        AttitudeAxis(code: "EXPRESSION", displayName: "표정"),
        AttitudeAxis(code: "POSTURE", displayName: "자세"),
        AttitudeAxis(code: "GESTURE", displayName: "손동작"),
        AttitudeAxis(code: "VOICE", displayName: "목소리")
    ]
    return VStack(spacing: .ds(.p24)) {
        // 선택=시선, 완료=표정·자세, 나머지 미완료
        AxisSegmentedBar(
            axes: axes,
            selected: axes[0],
            completedCodes: ["EXPRESSION", "POSTURE"],
            onSelect: { _ in }
        )
        // 아무것도 선택 안 됨(전부 미완료)
        AxisSegmentedBar(
            axes: axes,
            selected: nil,
            completedCodes: [],
            onSelect: { _ in }
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.dsBgDark)  // 영상 위 다크 배경 시뮬레이션
}
