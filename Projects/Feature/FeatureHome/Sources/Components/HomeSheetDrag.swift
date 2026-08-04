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
/// 드래그를 받는 자리는 자리별로 갈린다 — 기본 자리는 그래버·헤더 + **목록 판 전체**(스크롤을 끄고
/// 위 스와이프를 «시트 올리기» 로 쓴다), 확장 자리는 그래버 없이 헤더만(목록이 스크롤을 가져간다).
/// 스크롤과 시트 드래그는 같은 축이라 한 자리에서 둘을 동시에 살리면 서로 먹는다.
// TODO: 모션 시안 수령 후 임계값·스프링 확정 (지금 값은 구현자 판단 — 시안·모션 근거 없음).
enum HomeSheetDrag {
    /// 기본 자리의 시트 높이 — 시안 812 중 하단 481.
    // @ds(layout): 481 — 기본 자리 시트 높이
    static let reportHeight: CGFloat = 481
    /// 그린 영역이 인사말·안내 문구를 **자르지 않고** 담는 높이 — 시안 244(내비바 아래 ~ 시트 위).
    /// 기본 자리 시트가 이만큼은 남겨 둔다 — 안 그러면 시안보다 짧은 기기에서 인사말이 잘린다.
    /// 다만 이건 원칙값이고, 실제로 떼어 가는 값은 상한이 걸린 `greenHeight(available:)` 다.
    // @ds(layout): 244 — 그린 영역 최소 높이
    static let greenMinHeight: CGFloat = 244
    /// 자리를 한 칸 옮기는 최소 이동량(pt). 44(터치 최소 크기)보다 크게 잡아 탭 흔들림과 갈라진다.
    static let travelThreshold: CGFloat = 60
    /// 드래그로 인정하는 최소 이동 — 이보다 작으면 탭이다.
    static let minimumDistance: CGFloat = 10
    /// 시트를 다 내렸을 때 **홈 인디케이터 띠까지** 화면 밖으로 빼기 위한 여유 이동량.
    /// 판 배경이 하단 안전영역(최대 34)을 덮으므로 그만큼 더 내려야 아래 겹(면접 시작 CTA)이 안 가린다.
    /// 안전영역 실측을 뷰로 흘리는 대신 상한을 넉넉히 잡는다 — 더 내려가 봐야 이미 화면 밖이다.
    static let downwardClearance: CGFloat = 48
    /// 손을 뗀 뒤 남은 거리를 이어 미끄러뜨리는 곡선.
    static let settleAnimation: Animation = .snappy(duration: 0.32, extraBounce: 0.06)

    /// 자리별 시트 높이. `available` 은 내비바 아래로 쓸 수 있는 세로 길이다.
    ///
    /// 기본 자리는 **그린 영역이 먼저**다 — `greenHeight` 를 떼어 주고 남은 만큼만 시트가 먹는다.
    /// 시안(812) 에선 남는 값이 481 근처라 그대로고, 더 짧은 기기에서만 시트가 줄어 문구가 산다.
    static func height(for detent: HomeFeature.SheetDetent, available: CGFloat) -> CGFloat {
        switch detent {
        case .startInterview: 0
        case .report: min(reportHeight, max(available - greenHeight(available: available), 0))
        case .expanded: available
        }
    }

    /// 그린 영역이 실제로 떼어 가는 높이 — 원칙은 시안 244 지만, 그러고 나면 시트가 한 줄도 못 남는
    /// 짧은 컨테이너에선 **available 의 40% 까지만** 가져간다.
    ///
    /// 상한이 필요한 이유: 기본 자리 높이가 0 이 되면 그 자리와 «면접 시작» 자리가 **같은 높이(0)** 라
    /// `startProgress` 가 둘을 구분하지 못한다(기본 자리인데 면접 시작이 안 드러나거나 그 반대).
    /// 시트가 항상 조금이라도 남으면 두 자리가 값으로 갈린다.
    static func greenHeight(available: CGFloat) -> CGFloat {
        min(greenMinHeight, max(available * 0.4, 0))
    }

    /// 면접 시작이 드러난 정도(0…1) — 기본 자리 높이에서 0 으로 줄어드는 만큼 1 에 가까워진다.
    /// 인사말 두 벌(홈 ↔ 면접 시작)의 교차 페이드가 이 값을 쓴다.
    static func startProgress(sheetHeight: CGFloat, available: CGFloat) -> Double {
        let base = height(for: .report, available: available)
        guard base > 0 else { return 0 }
        return Double(1 - min(max(sheetHeight / base, 0), 1))
    }

    /// 기본 자리 아래로 내려갈 때 판을 **줄이지 않고 통째로 밀어 내리는** 세로 오프셋.
    ///
    /// 높이를 줄여 내리면 내용이 밑에서부터 잘려 나가다 홈 인디케이터 띠만 남는다 — 바텀시트가
    /// 미끄러져 사라지는 모양이 아니다. 그래서 기본 자리 밑으로는 높이를 고정하고 이 값만큼 민다.
    /// 다 내리면 `resting + downwardClearance` — 안전영역을 덮는 판 배경까지 화면 밖으로 나간다.
    static func dismissOffset(sheetHeight: CGFloat, available: CGFloat) -> CGFloat {
        let resting = height(for: .report, available: available)
        guard resting > 0, sheetHeight < resting else { return 0 }
        let progress = 1 - sheetHeight / resting
        return progress * (resting + downwardClearance)
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

    /// 좌표계는 **global** — 손잡이는 드래그를 따라 움직이는 뷰라, 기본(local)로 재면 판이 Δ 내려갈 때
    /// 좌표계도 같이 내려가 translation 이 되감기고, 그 값이 판을 도로 올리는 피드백 루프로 떨린다.
    var gesture: some Gesture {
        DragGesture(minimumDistance: HomeSheetDrag.minimumDistance, coordinateSpace: .global)
            .onChanged { onChanged($0.translation.height) }
            .onEnded { onEnded($0.predictedEndTranslation.height) }
    }
}
