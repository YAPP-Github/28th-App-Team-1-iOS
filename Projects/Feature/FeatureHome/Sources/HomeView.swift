//
//  HomeView.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import SwiftUI

/// 홈 진입점 — 화면은 1개, `phase` 스위치로 서브뷰를 연결한다(GuestFeedbackView 패턴).
/// 서브뷰 4개는 Figma 프레임과 1:1 스텁 — 시안 수령 시 각 파일에서 UI 를 채운다.
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
                HomeReportView()
            case let .startInterview(variant):
                HomeStartInterviewView(variant: variant)
            case let .duringInterview(variant):
                HomeDuringInterviewView(variant: variant)
            }
        }
        .onAppear { send(.onAppear) }
    }
}

#Preview("HomeDefault") {
    HomeView(
        store: Store(initialState: HomeFeature.State(showsOnboardingEntry: true, showsDebugLogout: true)) {
            HomeFeature()
        }
    )
}

#Preview("HomeStartInterview — 소진") {
    HomeView(
        store: Store(initialState: HomeFeature.State(phase: .startInterview(.exhausted))) {
            HomeFeature()
        }
    )
}

#Preview("HomeDuringInterview — 진행 중") {
    HomeView(
        store: Store(initialState: HomeFeature.State(phase: .duringInterview(.inProgress))) {
            HomeFeature()
        }
    )
}
