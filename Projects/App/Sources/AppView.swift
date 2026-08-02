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
            switch store.root {
            case .splash:
                // Splash(SP) — 세션 복구 판정 동안 표시. 판정은 AppFeature.onAppear.
                SplashView()
            case .splashFailed:
                // 판정 불가(네트워크·5xx) — 토큰은 살아 있으므로 로그인으로 내보내지 않고 재시도만 받는다.
                SplashView(onRetry: { store.send(.retryLaunchRouting) })
            case .updateRequired:
                // 강제 업데이트 — 세션 판정을 시작하지 않았다. 재시도 버튼 없이 알럿만 얹힌 Splash.
                SplashView()
            case .home:
                TabView(selection: $store.selectedTab) {
                    // 탭 루트마다 자기 NavigationStack — 홈의 네비바(로고 ↔ X 를 값으로 갈아끼움)는
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
            case .auth:
                // 로그인 전 + 가입 플로우(약관·온보딩) — 세션 복구가 게이트에 걸린 경우도 여기로 온다.
                AuthView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
        // 강제·권장 업데이트 안내 — 루트가 무엇이든 위에 얹힌다(강제는 root 가 .updateRequired).
        .alert($store.scope(state: \.updateAlert, action: \.updateAlert))
        .onAppear { store.send(.onAppear) }
        // 전역 시스템 로딩 — 모든 API in-flight(NetworkActivity) 동안 화면을 잠근다
        .hilitModal(isPresented: NetworkActivity.shared.isLoading) {
            LoadingModal()
        }
    }
}
