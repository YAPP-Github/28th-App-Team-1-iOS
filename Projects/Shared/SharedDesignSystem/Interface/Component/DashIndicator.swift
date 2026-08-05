//
//  DashIndicator.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

// Figma: «progress bar» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-1575
//        «dash» 435:1572 — Property 1=on 435:1573 (#1A1B1F) / off 435:1574 (#F6F7F9)
//        가이드 439:10412 «progress bar» 항목 — 「5 step」 행이 컨테이너, 「dash」 행이 조각 on/off

import SwiftUI

/// 진행 단계 표시용 대시 바 — Figma «progress bar» 컨테이너 하나에 대응한다.
/// 좌우 20 · 위아래 4 여백 안에서 조각을 간격 2 로 나열하고 **폭은 균등 분할**한다.
/// 켜짐 b800 / 꺼짐 g50, 모서리 0. 전체 높이 12(= 조각 4 + py4).
///
/// 조각 시안이 20×4 라고 고정폭으로 읽으면 안 된다 — 컨테이너가 `flex-1` 로 늘리므로
/// 시안 폭 w375 에서 조각은 65.4 가 된다((375 − 20×2 − 2×4) ÷ 5). 20 은 컴포넌트를
/// 그려둔 기본 폭일 뿐이고, 실제 폭은 «주어진 폭 − 여백 − 간격» 을 나눈 값이다.
///
/// 조각(`dash`)은 가이드에 on/off 두 변형으로 따로 그려져 있지만 공개하지 않는다.
/// 조각 단독으로는 폭이 정해지지 않아(위 문단) 쓸 자리가 없고, 남는 건 «bool → 색» 뿐이다
/// — `TabSelector` 가 탭 조각을 공개하지 않는 것과 같은 이유.
///
/// 시안은 5단계만 그려져 있으나(「5 step」) 균등 분할이라 `count` 가 몇이든 같은 규칙으로
/// 그려진다. `count: 5` 를 주면 시안과 픽셀 동일.
public struct DashIndicator: View {
    /// 시안 수치 — spacing 토큰 스케일에 없는 컴포넌트 고유 크기라 상수로 둔다.
    private enum Metric {
        /// 조각 두께. 균등 분할이라 폭은 상수가 아니다.
        static let dashHeight: CGFloat = 4
        /// 조각 사이 간격 — 토큰 스케일에 2 가 없다.
        static let gap: CGFloat = 2
    }

    private let count: Int
    private let current: Int

    /// - Parameters:
    ///   - count: 전체 단계 수. 시안은 5.
    ///   - current: 현재 단계(1-based). 이 값까지 켜진다. 범위를 넘으면 잘라낸다.
    public init(count: Int, current: Int) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        HStack(spacing: Metric.gap) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                Rectangle()
                    .fill(index < current ? Color.HilitBlack.b800 : Color.GrayScale.g50)
                    .frame(height: Metric.dashHeight)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p4))
    }
}

// 프리뷰 폭 375 = 시안 폭. 이 폭에서 조각이 65.4 로 떨어져야 시안과 같다.
private let previewWidth: CGFloat = 375

#Preview("5 step — 0/5 (시작 전)") {
    DashIndicator(count: 5, current: 0)
        .frame(width: previewWidth)
        .background(Color.BlackWhite.white)
}

#Preview("5 step — 1/5") {
    DashIndicator(count: 5, current: 1)
        .frame(width: previewWidth)
        .background(Color.BlackWhite.white)
}

#Preview("5 step — 2/5") {
    DashIndicator(count: 5, current: 2)
        .frame(width: previewWidth)
        .background(Color.BlackWhite.white)
}

#Preview("5 step — 3/5 (시안 435:1575)") {
    DashIndicator(count: 5, current: 3)
        .frame(width: previewWidth)
        .background(Color.BlackWhite.white)
}

#Preview("5 step — 4/5") {
    DashIndicator(count: 5, current: 4)
        .frame(width: previewWidth)
        .background(Color.BlackWhite.white)
}

#Preview("5 step — 5/5 (완료)") {
    DashIndicator(count: 5, current: 5)
        .frame(width: previewWidth)
        .background(Color.BlackWhite.white)
}

#Preview("단계 수 · 폭 변화 — 균등 분할") {
    VStack(spacing: .ds(.p20)) {
        DashIndicator(count: 3, current: 2)
        DashIndicator(count: 4, current: 3)
        DashIndicator(count: 7, current: 3)
        // 좁은 폭에서도 여백 20 은 유지되고 조각만 줄어든다.
        DashIndicator(count: 5, current: 3)
            .frame(width: 240)
    }
    .frame(width: previewWidth)
    .background(Color.BlackWhite.white)
}
