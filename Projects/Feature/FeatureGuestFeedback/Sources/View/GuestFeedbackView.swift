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

    /// 키보드 상단 y(글로벌) 실측 — 닉네임 패널 도킹 기준. ∞ = 키보드 없음.
    @State private var keyboardTopY: CGFloat = .infinity

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
        .overlay(alignment: .topTrailing) {
            if isTerminalPhase {
                closeButton
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Close (종착 화면 전용)

    /// 시안 «Part4 지인피드백» 의 온보딩·평가·요약에는 상단 X 가 없다 — 그래서 그리지 않는다.
    /// 완료·차단(`GuestGateView`)만 예외로 남긴다: 시안에 없는 코드 전용 종착 화면인데다,
    /// `closeTapped` 이 `delegate(.dismissed)` 의 **유일한 발신처**라 여기서도 지우면
    /// 실앱 fullScreenCover 를 내릴 방법이 사라진다(AppFeature 는 이 델리게이트로만 해제한다).
    private var isTerminalPhase: Bool {
        switch store.phase {
        case .completed, .gateClosed: true
        default: false
        }
    }

    /// 라이트 톤 게이트 배경에서 읽히도록 흰 원판 + g600 글리프.
    private var closeButton: some View {
        Button { send(.closeTapped) } label: {
            // @ds(icon): xmark 15pt semibold — 종착 화면 닫기. 시안에 없는 코드 전용 어포던스라 DS 아이콘 미지정.
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.GrayScale.g600)
                .padding(.ds(.p8))
                .background(Color.BlackWhite.white.opacity(0.9), in: Circle())
        }
        .padding(.ds(.p16))
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
    ///
    /// **딤 뒤 온보딩은 키보드가 떠도 제자리에 있어야 한다**(시안). 그런데 키보드가 뜨면 컨테이너
    /// 높이가 키보드만큼 줄고, 온보딩은 그보다 더 큰 최소 높이(≈706pt)를 가져 **넘친다** — SwiftUI 는
    /// 넘친 자식을 가운데 정렬하므로 넘친 만큼의 절반이 위로 밀려 올라간다(실측: 가용 458pt,
    /// 콘텐츠 706pt → (706-458)/2 = 124pt 위로. 타이틀이 상태바에 물리던 게 이것).
    ///
    /// `.ignoresSafeArea(.keyboard)` 로는 못 막는다 — 최소 재현으로 확인했다(적용/미적용 프레임 동일).
    /// 대신 **넘침을 가운데가 아니라 위로 정렬**시킨다: 컨테이너 크기를 갖는 `Color.clear` 를 바탕으로
    /// 두고 온보딩을 `.overlay(alignment: .top)` 으로 얹으면, 콘텐츠가 바탕보다 커도 정렬 기준이
    /// 상단이라 위로 밀리지 않는다. 키보드가 없을 땐 콘텐츠가 그대로 들어가 시안과 동일하다.
    ///
    /// 패널 상단은 화면 230/812 지점 고정이라 온보딩 타이틀을 전부 덮지 않는다 — 키보드가 올라오면
    /// 패널 내부 Spacer 만 압축된다. 딤 탭 = 시트 스와이프 취소(nicknameSheetDismissed), 온보딩에 머문다.
    private var onboardingPhase: some View {
        Color.clear
            .overlay(alignment: .top) {
                GuestOnboardingView(store: store)
            }
            .overlay {
                if store.isEnteringNickname {
                    Color.black.opacity(0.8)   // Figma 딤 node 1855:8617 — rgba(0,0,0,0.8), 대응 토큰 없음.
                        .ignoresSafeArea()
                        .onTapGesture { send(.nicknameSheetDismissed) }
                        .transition(.opacity)
                }
            }
            .overlay {
                if store.isEnteringNickname {
                    nicknamePanel
                }
            }
            .readsKeyboardTop(into: $keyboardTopY)
            .animation(.easeInOut(duration: 0.3), value: store.isEnteringNickname)
            .animation(.easeOut(duration: 0.25), value: keyboardTopY)
    }

    /// 닉네임 패널 — 상단은 화면 230/812 지점, 하단은 키보드 상단(없으면 세이프에어리어 바닥).
    private var nicknamePanel: some View {
        GeometryReader { geo in
            // size 는 키보드만큼 줄지만 그만큼 bottom inset 으로 되돌아와, 이 합은 화면 전체 높이로 일정하다.
            let fullHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            GuestNicknameView(store: store)
                // 기준은 화면 최상단이지만 측정은 세이프에어리어 안에서 하므로 상단 인셋을 뺀다.
                // 컨테이너를 상단까지 늘려(`.ignoresSafeArea(.container, edges: .top)`) 재면 그 계층이
                // 부모보다 커져 형제까지 재배치되므로 쓰지 않는다.
                .padding(.top, max(0, fullHeight * nicknameTopRatio - geo.safeAreaInsets.top))
                // 시스템 회피가 놓치는 한국어 후보 바 높이만큼의 보정 — [[KeyboardDock]].
                .padding(.bottom, geo.keyboardOverlap(below: keyboardTopY))
        }
        .transition(.move(edge: .bottom))
    }
}

#Preview {
    GuestFeedbackView(
        store: Store(initialState: GuestFeedbackFeature.State(token: "preview-token")) {
            GuestFeedbackFeature()
        }
    )
}
