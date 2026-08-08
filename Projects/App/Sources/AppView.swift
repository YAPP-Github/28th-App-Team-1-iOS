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
                // 탭이 하나뿐이라 TabView 를 두지 않는다 — 탭바 자리만 차지하면서 홈 배경 그라디언트가
                // 반투명 바로 새어 나와 하단에 초록 띠로 보였다. 탭이 둘 이상 생기면 그때 TabView 로 되돌린다.
                // 네비바(로고 ↔ X 를 값으로 갈아끼움)는 시스템 바 기반이라 스택 밖에선 조용히 안 그려진다
                // (navigation.md «부착 — push vs present»). 홈 내부 push 는 HomeFeature 의 Path/StackState 로 승격.
                NavigationStack {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                }
                // 온보딩 위저드 — 「면접 시작」의 [시작하기](첫 면접)·[수정하기], dev 진입 버튼이 연다.
                // 홈 위에서만 열리므로 로그인 이후다(온보딩 API 는 토큰 필요).
                .fullScreenCover(
                    item: $store.scope(state: \.onboarding, action: \.onboarding)
                ) { onboardingStore in
                    OnboardingView(store: onboardingStore)
                }
                // 면접 흐름(Part2) — 온보딩 완주가 넘긴 세션으로 열린다. 카메라 프리뷰가 전면을 채우는
                // 몰입 화면이라 네비바까지 덮는 fullScreenCover 다.
                .fullScreenCover(
                    item: $store.scope(state: \.interview, action: \.interview)
                ) { interviewStore in
                    InterviewView(store: interviewStore)
                }
                // 마이페이지(Part5) — 홈 위젯③ 이 연다. 자체 상단 바(`hilitPresentedNavigationBar`)를
                // 얹는 한 장짜리 화면이라 NavigationStack 없이 그대로 덮는다.
                .fullScreenCover(
                    item: $store.scope(state: \.myPage, action: \.myPage)
                ) { myPageStore in
                    MyPageView(store: myPageStore)
                }
            case .auth:
                // 로그인 전 + 가입 플로우(약관·온보딩) — 세션 복구가 게이트에 걸린 경우도 여기로 온다.
                AuthView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
        // 강제·권장 업데이트 안내 — 루트가 무엇이든 위에 얹힌다(강제는 root 가 .updateRequired).
        .alert($store.scope(state: \.updateAlert, action: \.updateAlert))
        .onAppear { store.send(.onAppear) }
        // 전역 시스템 로딩 — 모든 API in-flight(NetworkActivity) 동안 화면을 잠근다.
        // 루트라 `overlay` 변형을 쓴다 — 화면 모달(`hilitModal` = cover)과 presentation 자리를
        // 다투지 않게 하려는 것이고, 루트는 NavigationStack 밖이라 overlay 로도 네비바 위에 깔린다.
        .hilitModalOverlay(isPresented: showsGlobalLoading && NetworkActivity.shared.isLoading) {
            LoadingModal()
        }
    }

    /// 전역 로딩을 얹을 자리인지 — **Splash 계열 루트와 면접 중에는 끈다**.
    /// Splash 자체가 «기다리는 중» 표시라 그 위에 로딩 판을 또 덮으면 브랜드 화면만 가린다
    /// (세션 복구 판정이 곧 그 화면의 존재 이유다). `.updateRequired` 는 알럿이 떠 있어 딤이 겹치면 안 된다.
    private var showsGlobalLoading: Bool {
        // 면접은 자체 진행 표시(상태 칩·초읽기)로 대기를 말한다 — 답변 제출·질문 스트림마다 전역 딤이
        // 덮이면 면접이 끊겨 보이고, 타이머가 도는 화면을 잠그는 것 자체가 오동작이다.
        guard store.interview == nil else { return false }
        // `default` 를 두지 않는다 — 루트가 늘면 여기서 컴파일이 깨져 판단을 강제한다.
        return switch store.root {
        case .splash, .splashFailed, .updateRequired: false
        case .auth, .home: true
        }
    }
}
