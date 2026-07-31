//
//  HomeView.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 홈 진입점 — 홈 화면은 1개, `phase` 스위치로 서브뷰를 연결한다(GuestFeedbackView 패턴).
/// 면접 시작은 phase 가 아니라 cover 로 올라온다 — 홈 탭엔 NavigationStack 이 없어 push 경로가 없다.
///
/// 로고 내비바는 두 phase 뷰가 같은 바를 쓰므로 **여기서 한 번만** 붙인다(E1).
@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            switch store.phase {
            case .default:
                HomeDefaultView(store: store)
            case .report:
                HomeReportView(store: store)
            }
        }
        .hilitLogoNavigationBar(background: .filled, onProfile: { send(.userTappedProfile) })
        .onAppear { send(.onAppear) }
        .fullScreenCover(
            item: $store.scope(state: \.startInterview, action: \.startInterview)
        ) { startInterviewStore in
            StartInterviewView(store: startInterviewStore)
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
