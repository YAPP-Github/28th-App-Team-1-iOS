//
//  HomeView.swift
//  FeatureHomeImplementation
//
//  Created by 서정원 on 26/07/13.
//

// Figma: «Home_Default» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-16965
// Figma: «Home_Report»  https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-17266

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 홈 진입점 — 화면은 1개고 **겹을 쌓는 순서**가 전부다(Z 아래에서 위로):
///
/// 1. `HomeGreenBackdrop` — 장식 배경
/// 2. `StartInterviewView` — 시트가 내려간 만큼 드러나는 겹
/// 3. 인사말 + 스크롤 안내 — 배경 위 텍스트 두 줄
/// 4. `HomeReportSheet` — 기본 높이에 앉아 위로 확장·아래로 사라지는 판
///
/// 시안 프레임 `HomeDefault`·`HomeReport` 는 **같은 겹 구성**이고 다른 건 시트 내용(빈 상태 ↔ 목록)뿐이라
/// phase 별 화면 뷰를 두지 않는다(2026-08-04 통합 — 인사말이 두 뷰에 중복돼 있던 걸 여기 한 곳으로 올렸다).
/// 시트가 올라오면 3번을 덮는다 — 그래서 그린 영역을 «남은 높이» 로 계산하지 않고 그냥 겹으로 깐다.
///
/// 자리별 높이·착지 판정은 `HomeSheetDrag`. 내비바는 여기서 **한 번만** 붙인다 — 자리에 따라
/// 로고 바 ↔ X 바로 갈리는데, 모디파이어를 분기하면 씬이 통째로 새로 만들어져 드래그가 끊기므로
/// **값으로** 갈아끼운다(`HilitNavigationBar.Kind`).
@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
    @Bindable public var store: StoreOf<HomeFeature>

    /// 끌고 있는 동안의 시트 높이 보정치(아래로 끌면 +). 프레임마다 스토어를 때리지 않으려고
    /// 뷰가 들고, 손을 떼면 0 으로 돌아가며 확정된 자리가 다시 높이를 소유한다.
    @State private var dragTranslation: CGFloat = 0
    /// 손가락이 붙어 있는 동안만 true — 이때는 애니메이션을 끄고 이동량을 1:1 로 따라간다.
    @State private var isDragging = false

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            scene(available: proxy.size.height)
        }
        .hilitNavigationBar(navigationBarKind, background: .filled)
        .onAppear { send(.onAppear) }
    }

    // MARK: - 씬

    private func scene(available: CGFloat) -> some View {
        let sheetHeight = resolvedSheetHeight(available: available)
        let startProgress = HomeSheetDrag.startProgress(sheetHeight: sheetHeight, available: available)

        // 기본 자리 밑으로는 판을 줄이지 않고 통째로 밀어 내린다 — 바텀시트가 미끄러져 사라지는
        // 모양(HomeSheetDrag.dismissOffset). 그래서 판이 받는 높이는 기본 자리 밑에서 고정이다.
        let restingSheetHeight = HomeSheetDrag.height(for: .report, available: available)
        let displayHeight = max(sheetHeight, restingSheetHeight)
        let sheetOffset = HomeSheetDrag.dismissOffset(sheetHeight: sheetHeight, available: available)

        return ZStack(alignment: .bottom) {
            HomeGreenBackdrop()
                .ignoresSafeArea()

            // 면접 시작 — 시트 뒤에 늘 깔려 있고, 시트가 내려간 만큼 드러난다.
            StartInterviewView(store: store.scope(state: \.startInterview, action: \.startInterview))
                .opacity(startProgress)
                .allowsHitTesting(store.sheetDetent == .startInterview)

            greetingLayer
                .opacity(1 - startProgress)

            HomeReportSheet(
                store: store,
                // 펼칠 목록이 없으면 확장 자리를 막는다.
                dragHandle: dragHandle(available: available, allowsExpanded: store.phase != .default)
            )
                .frame(height: displayHeight)
                .offset(y: sheetOffset)
                // 투명해져도 탭은 그대로 먹는다 — 면접 시작 자리에선 아래 겹에 길을 내준다.
                .allowsHitTesting(store.sheetDetent != .startInterview)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 인사말의 colorBurn 이 «배경 커튼까지만» 섞이도록 합성 경계를 여기서 닫는다.
        .compositingGroup()
        // 끄는 중엔 손을 따라가고(nil), 놓은 뒤에만 남은 거리를 미끄러뜨린다.
        .animation(isDragging ? nil : HomeSheetDrag.settleAnimation, value: sheetHeight)
    }

    // MARK: - 인사말 겹

    /// 배경 위 텍스트 두 줄 — 위쪽에 붙여 두고, 올라오는 시트가 아래에서부터 덮는다.
    /// 시트가 기본 자리에 앉을 때 두 줄이 안 잘리도록 `HomeSheetDrag.greenHeight` 가 자리를 남긴다.
    ///
    /// 텍스트는 탭·드래그를 먹지 않는다(사용자 결정 2026-08-04) — `allowsHitTesting(false)` 를
    /// 겹 전체가 아니라 텍스트에만 건다. 옆에 붙는 dev 버튼은 눌려야 한다.
    private var greetingLayer: some View {
        VStack(spacing: 0) {
            if isGreetingVisible {
                HStack(alignment: .top, spacing: .ds(.p8)) {
                    greeting
                        .allowsHitTesting(false)
                    devReset
                }
                // @ds(spacing): 54 — 내비바 하단 ~ 인사말 (spacing 토큰은 4~24 뿐)
                .padding(.top, 54)
            }
            scrollHint
                // @ds(spacing): 60 — 인사말 ~ 스크롤 안내 (인사말이 없으면 내비바 아래 54 를 그대로 쓴다)
                .padding(.top, isGreetingVisible ? 60 : 54)
                .allowsHitTesting(false)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    /// 시안에 없는 dev 전용 버튼 — 인사말 옆. 배포 계에선 플래그가 꺼져 숨는다.
    /// 서버 로그아웃 + Keychain·온보딩 draft·UserDefaults 전체 삭제 후 Splash 부터 다시 태운다
    /// (소셜 로그인 화면까지 나간다 — 재설치와 같은 자리).
    @ViewBuilder
    private var devReset: some View {
        if store.showsDevReset {
            Button("초기화\n(dev)") { send(.userTappedResetAppData) }
                .buttonStyle(.bordered)
                .tint(.red)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .padding(.trailing, .ds(.p20))
        }
    }

    /// 인사말 표시 여부 — 기본 상태는 늘 띄우고, 리포트 상태는 변형이 정한다(`returning` 만).
    private var isGreetingVisible: Bool {
        store.phase != .report(.recent)
    }

    private var greeting: some View {
        // @ds(component): mix-blend-mode color-burn — 인사말이 배경 커튼과 타서 초록으로 보이는 효과. DS 에 블렌드 규칙 없음
        // 이름은 프로필 로드 결과라 응답 전엔 비어 있다 — 그때는 «님!» 만 남지 않게 이름 줄을 뺀다.
        Text(store.userName.isEmpty ? "오랜만이에요!" : "오랜만이에요\n\(store.userName)님!")
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .blendMode(.colorBurn)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
    }

    /// 스크롤 안내 — **문구일 뿐이다**(탭 제스처 없음, 사용자 결정 2026-08-04). 진입은 시트 드래그 하나.
    private var scrollHint: some View {
        // @ds(typography): Pretendard m16 / lh 1.4 / tracking -2% → body3 — 안내 문구 (토큰은 lh 1.3 · tracking -2.5%)
        Text("밑으로 스크롤해서 면접을 시작해 보세요!")
            .dsTypography(.body3)
            .foregroundStyle(Color.HilitGreen.g800)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .ds(.p10))
            .padding(.vertical, .ds(.p16))
            .padding(.horizontal, .ds(.p20))
    }

    // MARK: - 시트 자리

    /// 확정된 자리 높이에 진행 중인 드래그를 얹은 실제 높이.
    private func resolvedSheetHeight(available: CGFloat) -> CGFloat {
        let resting = HomeSheetDrag.height(for: store.sheetDetent, available: available)
        return min(max(resting - dragTranslation, 0), available)
    }

    private func dragHandle(available: CGFloat, allowsExpanded: Bool) -> HomeSheetDragHandle {
        HomeSheetDragHandle(
            // 목록 브리지가 «어디까지 시트가 먹는지» 를 가르는 값 — 높이 규칙은 여기서도 HomeSheetDrag 다.
            travelRange: HomeSheetDrag.travelRange(for: store.sheetDetent, available: available),
            onChanged: { translation in
                isDragging = true
                dragTranslation = translation
            },
            onEnded: { travel in
                let settled = HomeSheetDrag.settledDetent(
                    from: store.sheetDetent,
                    travel: travel,
                    allowsExpanded: allowsExpanded
                )
                // 보정치 해제와 자리 확정을 한 갱신으로 묶는다 — 갈라지면 높이가 한 번 튄다.
                isDragging = false
                dragTranslation = 0
                send(.userSettledSheet(settled))
                return settled
            }
        )
    }

    // MARK: - 내비바

    /// 자리에 따라 갈리는 바 변형. 면접 시작 자리의 X 는 «닫기» 가 아니라 «시트를 도로 올린다» 다.
    private var navigationBarKind: HilitNavigationBar.Kind {
        switch store.sheetDetent {
        case .startInterview:
            .standard(onClose: { send(.userSettledSheet(.report), animation: HomeSheetDrag.settleAnimation) })
        case .report, .expanded:
            .logo(onProfile: { send(.userTappedProfile) })
        }
    }
}

// MARK: - Previews

// 로고 내비바는 시스템 바라 스택 안에서만 그려진다 — 프리뷰에서 바를 보려면 `NavigationStack` 이 필요하다.
// 자리(`sheetDetent`)는 `onAppear` 가 기본으로 되돌리므로 확장 자리는 목록을 위로 끌어 확인한다.
#Preview("HomeDefault — 기록 없음") {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State()) {
                HomeFeature()
            } withDependencies: {
                // 빈 상태를 보려면 목록을 비워야 한다 — previewValue 는 5건을 준다.
                $0.interviewClient.reportList = { [] }
            }
        )
    }
}

#Preview("HomeDefault — dev 버튼") {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State(showsDevReset: true)) {
                HomeFeature()
            } withDependencies: {
                $0.interviewClient.reportList = { [] }
            }
        )
    }
}

#Preview("HomeReport — 인사말 표시") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.returning),
                    reports: HomeFeature.Report.placeholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}

// 픽스처는 첫 프레임용이고, `onAppear` 진입 로드가 `previewValue` 목록으로 덮는다 —
// 5건 중 GENERATING 1건은 행에서 빠져 4행이 남는다.
#Preview("HomeReport — 스냅샷 제목 목록") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.returning),
                    reports: HomeFeature.Report.snapshotPlaceholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}

// 인사말 숨김 변형(`recent`)은 지금 서버 재료가 없어 프리뷰 전용이다 — [[home]] «흐름» 참조.
#Preview("HomeReport — 인사말 숨김") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.recent),
                    reports: HomeFeature.Report.placeholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}
