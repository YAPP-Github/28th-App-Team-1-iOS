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
                // 온보딩 위저드 — 「면접 시작」의 [시작하기](첫 면접)·[수정하기], dev 진입 버튼이 연다.
                // 홈 탭 위에서만 열리므로 로그인 이후다(온보딩 API 는 토큰 필요).
                .fullScreenCover(
                    item: $store.scope(state: \.onboarding, action: \.onboarding)
                ) { onboardingStore in
                    OnboardingView(store: onboardingStore)
                }
                // 면접 흐름 — 위저드가 세션을 만든 직후 그 자리에서 열린다(온보딩 cover 는 이미 닫힌 뒤).
                // 카메라·마이크를 쓰는 전면 화면이라 탭 줄이 남으면 안 된다.
                .fullScreenCover(
                    item: $store.scope(state: \.interview, action: \.interview)
                ) { interviewStore in
                    InterviewView(store: interviewStore)
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
        .hilitModal(isPresented: showsGlobalLoading && NetworkActivity.shared.isLoading) {
            LoadingModal()
        }
    }

    /// 전역 로딩을 얹을 자리인지 — **Splash 계열 루트에서는 끈다**.
    /// Splash 자체가 «기다리는 중» 표시라 그 위에 로딩 판을 또 덮으면 브랜드 화면만 가린다
    /// (세션 복구 판정이 곧 그 화면의 존재 이유다). `.updateRequired` 는 알럿이 떠 있어 딤이 겹치면 안 된다.
    /// `default` 를 두지 않는다 — 루트가 늘면 여기서 컴파일이 깨져 판단을 강제한다.
    private var showsGlobalLoading: Bool {
        switch store.root {
        case .splash, .splashFailed, .updateRequired: false
        case .auth, .home: true
        }
    }
}
