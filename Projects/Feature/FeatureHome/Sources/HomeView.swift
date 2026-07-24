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

            // dev 디버그 — 서버 로그아웃 + 토큰·온보딩 draft 전체 삭제 후 첫 로그인 화면으로. 배포 계에선 숨겨진다.
            if store.showsDebugLogout {
                Button("로그아웃 (dev)", role: .destructive) {
                    send(.userTappedLogout)
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear { send(.onAppear) }
    }
}
