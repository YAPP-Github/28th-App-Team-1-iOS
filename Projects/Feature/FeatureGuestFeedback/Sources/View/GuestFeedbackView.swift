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
        // 밝은 영상 프레임 위에서도 흰 X 가 읽히게 하는 램프 — 스크림을 먼저 깔고 그 위에 X 를 얹는다.
        .overlay(alignment: .top) {
            if isDarkPhase {
                topScrim
            }
        }
        .overlay(alignment: .topLeading) { closeButton }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - 닫기 (좌상단)

    /// 실앱 fullScreenCover 의 유일한 탈출구 — 어느 phase 에서도 같은 자리(좌상단)에 둔다.
    /// **도착지는 여기가 정하지 않는다**: `delegate(.dismissed)` 만 올리고, 로그인돼 있으면 홈,
    /// 아니면 소셜 로그인 화면으로 보내는 판단은 AppFeature 몫이다 (사용자 결정 2026-08-14).
    /// 시안에 없는 코드 전용 어포던스라(게스트 화면엔 X 가 그려져 있지 않다) 위치·여백은
    /// DS 네비바(px20 · 44 바 안 24 글리프)를 눈으로 맞춘 값이다 — 스택 밖 cover 라 시스템 바가 안 그려진다.
    /// Example(내비 push)에선 delegate 를 아무도 안 받아 무반응 — 실앱 조립에서만 유효하다.
    private var closeButton: some View {
        Button { send(.closeTapped) } label: {
            // 다크 판(시작 연출·평가)은 흰 X, 라이트 판(온보딩·요약·게이트·로딩)은 기본 X.
            isDarkPhase ? Image.Cancel.white24 : Image.Cancel.default24
        }
        .padding(.leading, .ds(.p20))
        // @ds(layout): 10 — 44 바 안에서 24 글리프가 서는 높이((44-24)/2). spacing 스케일에 10 이 없다
        .padding(.top, 10)
    }

    /// DS `VideoOverlay(.darkClose)` 를 위아래로 뒤집어 상단에 깐다 — 리포트 플레이어 상단 스크림과 같은 방식.
    /// DS 램프는 «아래로 갈수록 진해지는» 방향뿐이라 방향만 뒤집는다. 탭을 먹지 않아(컴포넌트 내장)
    /// 스크림 뒤 영상 탭(컨트롤 토글)이 살아 있다.
    private var topScrim: some View {
        VideoOverlay(.darkClose)
            .scaleEffect(x: 1, y: -1)
            .ignoresSafeArea()
    }

    /// 바닥이 어두운 phase 인가 — X 글리프 색과 상단 스크림 노출을 가른다.
    /// 평가 화면만 다크(b800·영상)고 나머지(온보딩 g50·요약 white·게이트 g50)는 라이트다.
    private var isDarkPhase: Bool {
        switch store.phase {
        case .starting, .evaluating: true
        default: false
        }
    }

    // MARK: - Starting overlay + evaluation

    /// starting·evaluating 을 한 케이스로 묶는다 — 평가 화면은 계속 살아 있고,
    /// 시작 로딩(Figma `[4] 온보딩 - 면접 시작 로딩`, node 1855:8702)은 그 위 블러 오버레이일 뿐이다.
    /// 영상 준비·최소 노출이 서서 phase 가 evaluating 이 되면 프로토타입 Flow 1(1855:8702 → 1855:9821)대로
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
