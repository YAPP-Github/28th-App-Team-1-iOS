//
//  AppView.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import SwiftUI
import ComposableArchitecture
import CoreNetworkInterface
import Feature
import SharedDesignSystemInterface

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.isAuthenticated {
                TabView(selection: $store.selectedTab) {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                        .tabItem { Label("홈", systemImage: "house") }
                        .tag(AppFeature.Tab.home)
                }
                // dev 전용 온보딩 위저드 — Home 진입 버튼으로만 열린다 (로그인 이후이므로 토큰 보유).
                .fullScreenCover(
                    item: $store.scope(state: \.onboarding, action: \.onboarding)
                ) { onboardingStore in
                    OnboardingView(store: onboardingStore)
                }
            } else {
                AuthView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
        .onAppear { store.send(.onAppear) }
        // 전역 시스템 로딩 — 모든 API in-flight(NetworkActivity) 동안 화면을 잠근다
        .hilitModal(isPresented: NetworkActivity.shared.isLoading) {
            LoadingModal()
        }
    }
}
