//
//  SheetGrabber.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/08/06.
//

// Figma: 바텀시트 손잡이 — «Home_Report_Sheet» · «Report_HighlightDetail_Sheet» 443:7324 머리의 막대

import SwiftUI

/// 바텀시트 손잡이 — g400 60×5 막대(모서리 0)를 높이 20 줄 가운데에 놓는다.
///
/// 시스템 `presentationDragIndicator` 는 규격(캡슐·색)이 시안과 달라 숨기고 이걸 얹는다
/// (`.hilitDetentSheet` 가 인디케이터를 `.hidden` 으로 못박아 둔 이유).
///
/// **제스처는 이 타입이 갖지 않는다** — 시스템 시트는 드래그가 OS 몫이라 손잡이가 그림뿐이고,
/// 오버레이 시트는 호출부가 직접 드래그를 붙여야 한다(`CountdownCard` 와 같은 판단).
/// 줄 전체(높이 20)가 `contentShape` 라 호출부가 `.gesture(…)` 만 붙이면 빈자리까지 잡힌다.
///
/// ```swift
/// VStack(spacing: 0) {
///     SheetGrabber()                       // 시스템 시트 — 그림만
///     SheetGrabber().gesture(drag)         // 오버레이 시트 — 직접 끌기
///     content
/// }
/// ```
public struct SheetGrabber: View {
    public init() {}

    public var body: some View {
        Color.GrayScale.g400
            .frame(width: Metric.barWidth, height: Metric.barHeight)
            .frame(maxWidth: .infinity)
            .frame(height: Metric.rowHeight)
            // 막대만이 아니라 줄 전체가 손잡이다 — 호출부가 붙이는 드래그의 판정 영역.
            .contentShape(Rectangle())
    }

    /// 시안 수치 — spacing 토큰 스케일에 없는 컴포넌트 고유 크기라 상수로 둔다.
    private enum Metric {
        static let barHeight: CGFloat = 5
        static let barWidth: CGFloat = 60
        /// 막대를 담는 줄 높이 — 시트 상단 여백을 겸한다.
        static let rowHeight: CGFloat = 20
    }
}

#Preview {
    VStack(spacing: 0) {
        SheetGrabber()
        Text("시트 본문")
            .dsTypography(.body3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .background(Color.HilitBlack.b900)
}
