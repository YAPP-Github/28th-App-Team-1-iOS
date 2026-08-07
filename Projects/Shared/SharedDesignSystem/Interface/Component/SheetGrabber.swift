//
//  SheetGrabber.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/08/07.
//

// Figma: 바텀시트 손잡이 — «Create_Account_Terms of Service_Detail» 477:6341 · «Home_Report_Sheet» 머리의 막대

import SwiftUI

/// 바텀시트 손잡이 — g400 60×5 막대(모서리 0)를 높이 20 줄 가운데에 놓는다.
///
/// 시스템 `presentationDragIndicator`(캡슐·회색 반투명)와 규격이 달라 직접 그린다. 시트 자체가
/// 시스템 것이 아니게 된 뒤로는(`.hilitBottomSheet` 오버레이) 비교 대상도 사라졌다.
///
/// **제스처는 이 타입이 갖지 않는다** — 손잡이는 그림이고, 끌어서 자리를 옮기는 판정은 시트 높이를
/// 소유한 쪽에 있다. `.hilitBottomSheet` 는 이 줄을 직접 얹고 제스처도 자기가 붙이므로 호출부는
/// 손댈 게 없다. 화면에 상주하는 시트(홈 리포트 판처럼 모디파이어를 안 쓰는 것)만 직접 쓴다.
/// 줄 전체(높이 20)가 `contentShape` 라 막대 밖 빈자리까지 잡힌다.
///
/// ```swift
/// VStack(spacing: 0) {
///     SheetGrabber().gesture(drag)   // 화면 상주 시트 — 자리도 화면이 소유한다
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
            // 막대만이 아니라 줄 전체가 손잡이다 — 붙는 드래그의 판정 영역.
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
    .background(Color.BlackWhite.white)
}
