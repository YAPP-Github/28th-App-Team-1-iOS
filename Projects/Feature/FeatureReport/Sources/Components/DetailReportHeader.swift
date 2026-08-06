//
//  DetailReportHeader.swift
//  FeatureReport
//
//  Created by EunSeo on 26/08/06.
//

// Figma: «Report_Main_Default» 제목 줄 443:7219 · 말풍선 443:7261
//        https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-7204

import SharedDesignSystemInterface
import SwiftUI

/// «상세 리포트» 제목 줄 — 레드플래그가 있을 때만 느낌표와 말풍선이 함께 붙는다 (정의서 §2-4).
///
/// 말풍선은 오버레이라 열고 닫아도 아래 질문 탭이 밀리지 않는다.
/// 가로 위치는 **«꼬리 끝 = 느낌표 오른쪽 끝»** 으로 잡는다 — 좌표를 박지 않아 제목 글자폭이 바뀌어도
/// 꼬리가 계속 느낌표를 가리킨다 (시안은 제목 80 + 간격 8 + 느낌표 16 기준으로 말풍선 왼쪽이 65).
struct DetailReportHeader: View {
    /// 레드플래그 안내 문구. nil 이면 느낌표·말풍선을 **둘 다** 그리지 않는다.
    let notice: String?
    let isTooltipVisible: Bool
    let onTapIcon: () -> Void
    let onTapTooltip: () -> Void

    var body: some View {
        titleRow
            .overlay(alignment: Alignment(horizontal: .redFlagTail, vertical: .top)) {
                if let notice, isTooltipVisible {
                    tooltip(notice)
                }
            }
    }

    private var titleRow: some View {
        HStack(spacing: .ds(.p8)) {
            Text("상세 리포트")
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)

            if notice != nil {
                Button(action: onTapIcon) {
                    Image.Issue.error16
                }
                .buttonStyle(.plain)
                // 꼬리가 겨눌 지점 — 느낌표 오른쪽 끝. HStack 은 자기 축(세로)이 아닌
                // 이 가로 가이드를 그대로 위로 올려보내서 오버레이가 집어 쓴다.
                .alignmentGuide(.redFlagTail) { $0[.trailing] }
            }
            Spacer(minLength: 0)
        }
    }

    /// 말풍선 — 누르면 접히고, 화면에 다시 들어오면 리듀서가 도로 띄운다.
    /// 폭은 고정이 아니라 내용폭(`.mini`)이고 상한만 둔다 — 시안 문구가 마침 상한과 같은 273 이다.
    private func tooltip(_ notice: String) -> some View {
        BubbleField(notice, .mini(mood: .dark))
            .frame(maxWidth: Metric.tooltipMaxWidth)
            .fixedSize(horizontal: false, vertical: true)
            .alignmentGuide(.redFlagTail) { _ in BubbleField.tailInset }
            // 꼬리 끝이 제목 위 28 에 오도록 자기 높이만큼 끌어올린다 (시안 443:7261).
            .alignmentGuide(.top) { $0[.bottom] + Metric.tooltipBottomGap }
            .onTapGesture(perform: onTapTooltip)
    }

    private enum Metric {
        // @ds(spacing): 28 — 말풍선 꼬리 끝과 제목 사이
        static let tooltipBottomGap: CGFloat = 28
        // @ds(layout): 273 — 말풍선 최대 폭 (시안 443:7261)
        static let tooltipMaxWidth: CGFloat = 273
    }
}

/// 말풍선 꼬리 끝과 느낌표를 맞추는 가로 축. 느낌표가 없으면 쓰이지 않는다(기본값은 왼쪽 끝).
private enum RedFlagTailAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context[.leading] }
}

private extension HorizontalAlignment {
    static let redFlagTail = HorizontalAlignment(RedFlagTailAlignment.self)
}

#Preview {
    VStack(alignment: .leading, spacing: .ds(.p40)) {
        DetailReportHeader(
            notice: "영상 해상도가 낮아 분석율이 떨어질 수 있어요.",
            isTooltipVisible: true,
            onTapIcon: {},
            onTapTooltip: {}
        )
        DetailReportHeader(notice: nil, isTooltipVisible: true, onTapIcon: {}, onTapTooltip: {})
    }
    .padding(.horizontal, .ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
