//
//  HomeView.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 홈 진입점 — 홈 화면은 1개다. `phase` 스위치가 시트 안팎의 내용을 고르고(GuestFeedbackView 패턴),
/// **시트가 앉는 자리**(`sheetDetent`)가 그 위 레이아웃을 정한다.
///
/// 한 씬에 세 겹이 쌓인다 — 그린 배경 / 면접 시작 / (인사말 + 리포트 시트).
/// 시트를 내리면 뒤에 깔린 면접 시작이 드러나므로 cover present 가 아니다(끌던 손을 놓기 전까진
/// 되돌릴 수 있어야 한다). 자리별 높이·착지 판정은 `HomeSheetDrag`.
///
/// 내비바는 두 phase 뷰가 같은 바를 쓰므로 **여기서 한 번만** 붙인다(E1). 자리에 따라
/// 로고 바 ↔ X 바로 갈리는데, 모디파이어를 분기하면 씬이 통째로 새로 만들어져 드래그가 끊기므로
/// **값으로** 갈아끼운다(`HilitNavigationBar.Kind`).
@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    /// 끌고 있는 동안의 시트 높이 보정치(아래로 끌면 +). 프레임마다 스토어를 때리지 않으려고
    /// 뷰가 들고, 손을 떼면 0 으로 돌아가며 확정된 자리가 다시 높이를 소유한다.
    @State private var dragTranslation: CGFloat = 0
    /// 손가락이 붙어 있는 동안만 true — 이때는 애니메이션을 끄고 이동량을 1:1 로 따라간다.
    @State private var isDragging = false

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            scene(available: proxy.size.height)
        }
        .hilitNavigationBar(navigationBarKind, background: .filled)
        // 면접 시작 시안엔 탭 줄이 없다 — cover 였을 땐 덮여서 안 보였고, 씬의 한 겹이 된 지금은 직접 숨긴다.
        .toolbar(store.sheetDetent == .startInterview ? .hidden : .visible, for: .tabBar)
        .onAppear { send(.onAppear) }
    }

    // MARK: - 씬

    private func scene(available: CGFloat) -> some View {
        let sheetHeight = resolvedSheetHeight(available: available)
        let startProgress = HomeSheetDrag.startProgress(sheetHeight: sheetHeight, available: available)

        return ZStack {
            HomeGreenBackdrop()
                .ignoresSafeArea()

            // 면접 시작 — 시트 뒤에 늘 깔려 있고, 시트가 내려간 만큼 드러난다.
            StartInterviewView(store: store.scope(state: \.startInterview, action: \.startInterview))
                .opacity(startProgress)
                .allowsHitTesting(store.sheetDetent == .startInterview)

            phaseContent(sheetHeight: sheetHeight, startProgress: startProgress)
                // 투명해져도 탭은 그대로 먹는다 — 면접 시작 자리에선 아래 겹에 길을 내준다.
                .allowsHitTesting(store.sheetDetent != .startInterview)
        }
        // 인사말의 colorBurn 이 «배경 커튼까지만» 섞이도록 합성 경계를 여기서 닫는다.
        .compositingGroup()
        // 끄는 중엔 손을 따라가고(nil), 놓은 뒤에만 남은 거리를 미끄러뜨린다.
        .animation(isDragging ? nil : HomeSheetDrag.settleAnimation, value: sheetHeight)
    }

    @ViewBuilder
    private func phaseContent(sheetHeight: CGFloat, startProgress: Double) -> some View {
        switch store.phase {
        case .default:
            HomeDefaultView(
                store: store,
                sheetHeight: sheetHeight,
                startProgress: startProgress,
                // 빈 상태엔 펼칠 목록이 없어 확장 자리를 막는다.
                dragHandle: dragHandle(allowsExpanded: false)
            )
        case .report:
            HomeReportView(
                store: store,
                sheetHeight: sheetHeight,
                startProgress: startProgress,
                dragHandle: dragHandle(allowsExpanded: true)
            )
        }
    }

    // MARK: - 시트 자리

    /// 확정된 자리 높이에 진행 중인 드래그를 얹은 실제 높이.
    private func resolvedSheetHeight(available: CGFloat) -> CGFloat {
        let resting = HomeSheetDrag.height(for: store.sheetDetent, available: available)
        return min(max(resting - dragTranslation, 0), available)
    }

    private func dragHandle(allowsExpanded: Bool) -> HomeSheetDragHandle {
        HomeSheetDragHandle(
            onChanged: { translation in
                isDragging = true
                dragTranslation = translation
            },
            onEnded: { travel in
                let settled = HomeSheetDrag.settledDetent(
                    from: store.sheetDetent,
                    travel: travel,
                    allowsExpanded: allowsExpanded
                )
                // 보정치 해제와 자리 확정을 한 갱신으로 묶는다 — 갈라지면 높이가 한 번 튄다.
                isDragging = false
                dragTranslation = 0
                send(.userSettledSheet(settled))
            }
        )
    }

    // MARK: - 내비바

    /// 자리에 따라 갈리는 바 변형. 면접 시작 자리의 X 는 «닫기» 가 아니라 «시트를 도로 올린다» 다.
    private var navigationBarKind: HilitNavigationBar.Kind {
        switch store.sheetDetent {
        case .startInterview:
            .standard(onClose: { send(.userSettledSheet(.report), animation: HomeSheetDrag.settleAnimation) })
        case .report, .expanded:
            .logo(onProfile: { send(.userTappedProfile) })
        }
    }
}

// MARK: - Previews

// 로고 내비바는 시스템 바라 스택 안에서만 그려진다 — 프리뷰에서 바를 보려면 `NavigationStack` 이 필요하다.
#Preview("HomeDefault") {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State(showsOnboardingEntry: true, showsDebugLogout: true)) {
                HomeFeature()
            }
        )
    }
}

#Preview("HomeReport — 인사말 표시") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.returning),
                    reports: HomeFeature.Report.placeholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}

#Preview("HomeReport — 인사말 숨김") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.recent),
                    reports: HomeFeature.Report.placeholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}
