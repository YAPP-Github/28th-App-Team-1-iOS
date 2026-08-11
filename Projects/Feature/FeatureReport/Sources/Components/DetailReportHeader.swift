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
/// 말풍선은 오버레이라 열고 닫아도 아래 질문 탭이 밀리지 않고, 세로로는 **제목 위**에 뜬다
/// (아래로 두면 질문 탭을 덮는다 — 시안 443:7261).
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
    /// 폭은 고정이 아니라 내용폭(`.mini`)이고 상한만 둔다 — 상한(274)에서 줄바꿈하고, 짧으면 왼쪽에 붙어
    /// 꼬리(왼쪽에서 40)가 제자리를 지킨다.
    private func tooltip(_ notice: String) -> some View {
        BubbleField(notice, .mini(mood: .dark))
            .frame(maxWidth: Metric.tooltipMaxWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            // 탭 판정은 말풍선 자기 크기에서 받는다 — 아래 «높이 0» 프레임에 달면 판정이 사라진다.
            .onTapGesture(perform: onTapTooltip)
            .padding(.bottom, Metric.tooltipBottomGap)
            // 높이 0 프레임의 «바닥»에 붙여 자기 높이만큼 위로 넘치게 둔다 — 오버레이 기준선(제목 위쪽)
            // 위로 통째로 올라가 질문 탭을 덮지 않는다 (시안 443:7261).
            .frame(height: 0, alignment: .bottom)
            // 가로 정렬 축은 프레임 밖에서 다시 세운다 — `frame` 은 자식의 커스텀 가이드를 물려주지 않는다.
            .alignmentGuide(.redFlagTail) { _ in BubbleField.tailInset }
    }

    private enum Metric {
        // @ds(spacing): 8 — 말풍선 꼬리 끝과 제목 사이
        static let tooltipBottomGap: CGFloat = 8
        // @ds(layout): 274 — 말풍선 최대 폭 (시안 443:7261)
        static let tooltipMaxWidth: CGFloat = 274
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
    // 말풍선이 제목 «위»로 넘쳐 나가므로 프리뷰 위쪽을 비워 둔다.
    .padding(.top, .ds(.p40))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.HilitBlack.b900)
}
