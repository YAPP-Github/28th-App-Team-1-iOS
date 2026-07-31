//
//  HomeView.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import SwiftUI

/// 홈 진입점 — 홈 화면은 1개, `phase` 스위치로 서브뷰를 연결한다(GuestFeedbackView 패턴).
/// 면접 시작은 phase 가 아니라 cover 로 올라온다 — 홈 탭엔 NavigationStack 이 없어 push 경로가 없다.
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
            case let .report(variant):
                HomeReportView(isGreetingVisible: variant == .returning)
            }
        }
        .onAppear { send(.onAppear) }
        .fullScreenCover(
            item: $store.scope(state: \.startInterview, action: \.startInterview)
        ) { startInterviewStore in
            StartInterviewView(store: startInterviewStore)
        }
    }
}

// MARK: - Previews

#Preview("HomeDefault") {
    HomeView(
        store: Store(initialState: HomeFeature.State(showsOnboardingEntry: true, showsDebugLogout: true)) {
            HomeFeature()
        }
    )
}

#Preview("HomeReport — 인사말 표시") {
    HomeView(
        store: Store(initialState: HomeFeature.State(phase: .report(.returning))) {
            HomeFeature()
        }
    )
}

#Preview("HomeReport — 인사말 숨김") {
    HomeView(
        store: Store(initialState: HomeFeature.State(phase: .report(.recent))) {
            HomeFeature()
        }
    )
}
