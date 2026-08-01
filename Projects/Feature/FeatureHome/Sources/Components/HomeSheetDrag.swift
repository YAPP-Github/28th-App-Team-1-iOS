//
//  HomeSheetDrag.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import SwiftUI

/// 「밑으로 스크롤해서 면접을 시작해 보세요!」 — 시안 문구가 약속한 전환의 제스처 쪽 절반.
/// 리포트 시트를 끌어 자리(`HomeFeature.SheetDetent`)를 바꾸는 규칙(치수·임계값·착지 판정)을
/// 한 곳에 둬 두 phase 뷰(`HomeDefaultView`·`HomeReportView`)가 같은 판정을 쓰게 한다.
///
/// 손잡이(그래버·헤더)에만 드래그를 건다 — 목록은 `ScrollView` 라 같은 축의 드래그가 겹친다.
// TODO: 모션 시안 수령 후 임계값·스프링 확정 (지금 값은 구현자 판단 — 시안·모션 근거 없음).
enum HomeSheetDrag {
    /// 기본 자리의 시트 높이 — 시안 812 중 하단 481.
    // @ds(layout): 481 — 기본 자리 시트 높이
    static let reportHeight: CGFloat = 481
    /// 자리를 한 칸 옮기는 최소 이동량(pt). 44(터치 최소 크기)보다 크게 잡아 탭 흔들림과 갈라진다.
    static let travelThreshold: CGFloat = 60
    /// 드래그로 인정하는 최소 이동 — 이보다 작으면 탭이다.
    static let minimumDistance: CGFloat = 10
    /// 손을 뗀 뒤 남은 거리를 이어 미끄러뜨리는 곡선.
    static let settleAnimation: Animation = .snappy(duration: 0.32, extraBounce: 0.06)

    /// 자리별 시트 높이. `available` 은 내비바 아래로 쓸 수 있는 세로 길이다.
    static func height(for detent: HomeFeature.SheetDetent, available: CGFloat) -> CGFloat {
        switch detent {
        case .startInterview: 0
        case .report: min(reportHeight, available)
        case .expanded: available
        }
    }

    /// 면접 시작이 드러난 정도(0…1) — 기본 자리 높이에서 0 으로 줄어드는 만큼 1 에 가까워진다.
    /// 인사말 두 벌(홈 ↔ 면접 시작)의 교차 페이드가 이 값을 쓴다.
    static func startProgress(sheetHeight: CGFloat, available: CGFloat) -> Double {
        let base = height(for: .report, available: available)
        guard base > 0 else { return 0 }
        return Double(1 - min(max(sheetHeight / base, 0), 1))
    }

    /// 손을 뗐을 때 앉을 자리. `travel` 은 관성까지 반영한 예상 종료 이동량(아래가 +).
    ///
    /// 임계값을 못 넘으면 원래 자리가 아니라 **기본 자리**로 돌아간다
    /// (사용자 결정 2026-08-01 — «와리가리 타다 도중에 놓치면 default 대로»).
    static func settledDetent(
        from current: HomeFeature.SheetDetent,
        travel: CGFloat,
        allowsExpanded: Bool
    ) -> HomeFeature.SheetDetent {
        if travel > travelThreshold {
            return stepDown(from: current)
        } else if travel < -travelThreshold {
            return stepUp(from: current, allowsExpanded: allowsExpanded)
        } else {
            return .report
        }
    }

    /// 한 칸 아래 — 확장 → 기본 → 면접 시작.
    private static func stepDown(from detent: HomeFeature.SheetDetent) -> HomeFeature.SheetDetent {
        switch detent {
        case .expanded: .report
        case .report, .startInterview: .startInterview
        }
    }

    /// 한 칸 위 — 면접 시작 → 기본 → 확장. 펼칠 목록이 없으면 기본에서 멈춘다.
    private static func stepUp(
        from detent: HomeFeature.SheetDetent,
        allowsExpanded: Bool
    ) -> HomeFeature.SheetDetent {
        switch detent {
        case .startInterview: .report
        case .report, .expanded: allowsExpanded ? .expanded : .report
        }
    }
}

/// 시트 손잡이가 부모(`HomeView`)에게 드래그를 되돌려 주는 통로.
/// 자리·높이는 부모가 소유하고, phase 뷰는 «어디를 잡을 수 있는지»만 정한다.
struct HomeSheetDragHandle {
    /// 끄는 중 — 세로 이동량(아래가 +)을 그대로 흘린다.
    let onChanged: (CGFloat) -> Void
    /// 손을 뗌 — 관성 포함 예상 종료 이동량을 넘긴다.
    let onEnded: (CGFloat) -> Void

    var gesture: some Gesture {
        DragGesture(minimumDistance: HomeSheetDrag.minimumDistance)
            .onChanged { onChanged($0.translation.height) }
            .onEnded { onEnded($0.predictedEndTranslation.height) }
    }
}
