//
//  GuestFeedbackView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

@ViewAction(for: GuestFeedbackFeature.self)
public struct GuestFeedbackView: View {
    @Bindable public var store: StoreOf<GuestFeedbackFeature>

    /// Figma 시안2 실측 — 패널 상단 y230 / 화면 812 비례(node 2094:7566).
    private let nicknameTopRatio: CGFloat = 230.0 / 812.0

    public init(store: StoreOf<GuestFeedbackFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            switch store.phase {
            case .loading:
                ProgressView("불러오는 중이에요")
            case .onboarding:
                onboardingPhase
            case .starting, .evaluating:
                evaluationPhase
            case .summary:
                GuestSummaryView(store: store)
            case .completed:
                GuestGateView(kind: .completed)
            case .gateClosed(let reason):
                GuestGateView(kind: .closed(reason))
            }
        }
        .onAppear { send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
        .confirmationDialog($store.scope(state: \.confirmDialog, action: \.confirmDialog))
    }

    // MARK: - Starting overlay + evaluation

    /// starting·evaluating 을 한 케이스로 묶는다 — 평가 화면은 계속 살아 있고,
    /// 시작 로딩(Figma `[4] 온보딩 - 면접 시작 로딩`, node 1855:8702)은 그 위 블러 오버레이일 뿐이다.
    /// videoReady 로 phase 가 evaluating 이 되면 프로토타입 Flow 1(1855:8702 → 1855:9821)대로
    /// 오버레이(딤+블러+문구)가 페이드아웃하고, 동시에 평가 화면의 축 세그먼트 바가 아래에서 슬라이드업한다
    /// (슬라이드업은 GuestEvaluationView 쪽 — 같은 0.35s easeOut 커브로 동기).
    /// 스위치 케이스가 갈리면 뷰 정체성이 끊겨 이 크로스페이드가 불가능하다. 연출 중엔 아래 화면이 터치를 받지 않는다.
    private var evaluationPhase: some View {
        GuestEvaluationView(store: store)
            .allowsHitTesting(store.phase != .starting)
            .overlay {
                if store.phase == .starting {
                    GuestStartingView(store: store)
                        .transition(.opacity)
                }
            }
            // 프로토타입 리액션의 duration/easing 은 MCP 로 노출되지 않아 Figma smart animate 기본(300ms ease-out)에 맞췄다.
            .animation(.easeOut(duration: 0.35), value: store.phase)
    }

    // MARK: - Onboarding + nickname overlay

    /// 닉네임 입력(Figma `온보딩 - 닉네임 입력 / 시안2`, 패널 node 2094:7566) — `.sheet` 대신 커스텀 오버레이.
    /// 두 계층으로 나눠 키보드를 다룬다:
    /// - 배경 계층(온보딩+딤)은 키보드 세이프에어리어를 무시해 키보드가 떠도 전체 화면에 고정.
    /// - 패널 계층은 시스템 키보드 회피에 참여 — 하단 CTA 가 키보드 위로 도킹하고, 상단은
    ///   화면 230/812 지점 고정이라 온보딩 타이틀을 전부 덮지 않는다. 내부 Spacer 만 압축된다.
    /// 딤 탭 = 시트 스와이프 취소와 동일(nicknameSheetDismissed) — 온보딩에 머문다.
    private var onboardingPhase: some View {
        ZStack(alignment: .top) {
            ZStack {
                GuestOnboardingView(store: store)
                if store.isEnteringNickname {
                    Color.black.opacity(0.8)   // Figma 딤 node 1855:8617 — rgba(0,0,0,0.8), 대응 토큰 없음.
                        .ignoresSafeArea()
                        .onTapGesture { send(.nicknameSheetDismissed) }
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea(.keyboard)

            if store.isEnteringNickname {
                GeometryReader { geo in
                    // 키보드와 무관한 화면 전체 높이 — size 는 키보드만큼 줄지만 그만큼 bottom inset 으로 되돌아온다.
                    let fullHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                    GuestNicknameView(store: store)
                        .padding(.top, fullHeight * nicknameTopRatio)
                }
                // 상단 오프셋 기준을 화면 최상단으로 — 하단(홈 인디케이터·키보드) 인셋은 유지.
                .ignoresSafeArea(.container, edges: .top)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isEnteringNickname)
    }
}

#Preview {
    GuestFeedbackView(
        store: Store(initialState: GuestFeedbackFeature.State(token: "preview-token")) {
            GuestFeedbackFeature()
        }
    )
}
