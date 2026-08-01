//
//  AppView.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import SwiftUI
import ComposableArchitecture
import Feature

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.isCheckingSession {
                // Splash(SP) — 자동 로그인 판정 동안 표시. 판정은 AppFeature.onAppear.
                SplashView()
            } else if store.isAuthenticated {
                TabView(selection: $store.selectedTab) {
                    // 탭 루트마다 자기 NavigationStack — 홈의 내비바(로고 ↔ X 를 값으로 갈아끼움)는
                    // 시스템 바 기반이라 스택 밖에선 조용히 안 그려진다 (navigation.md «부착 — push vs present»).
                    // 홈 내부 push 가 생기면 HomeFeature 의 Path/StackState 로 승격한다.
                    NavigationStack {
                        HomeView(store: store.scope(state: \.home, action: \.home))
                    }
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
    }
}
