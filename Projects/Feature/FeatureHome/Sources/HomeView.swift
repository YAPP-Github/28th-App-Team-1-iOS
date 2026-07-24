//
//  HomeView.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Home")

            // dev 전용 임시 진입 — 온보딩 본체 통합 전까지 실서버 API 확인용. 배포 계에선 숨겨진다.
            if store.showsOnboardingEntry {
                Button("온보딩 시작 (dev)") {
                    send(.userTappedOnboarding)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear { send(.onAppear) }
    }
}
