//
//  HilitBottomSheet.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: 시트 판 규격은 화면마다 다르지만 룩은 공통 — 화면 폭 꽉 · 상단 모서리 0 · 머리에 그래버.
//        «Create_Account_Terms of Service_Detail» 477:6341 (높이 662/812) 가 기준 인스턴스.

import SwiftUI

public extension View {
    /// 바텀시트 — 딤 위에 화면 폭을 꽉 채운 판을 바닥에서 올린다. **시스템 `.sheet` 을 쓰지 않는다.**
    ///
    /// iOS 26 은 부분 높이 시트를 화면 가장자리에서 띄워 그린다(양옆·아래 여백 + 큰 라운드). 시안은
    /// 폭을 꽉 채운 모서리 0 판이라 그 룩이 다른 물건이 됐고 디자인이 반려했다(이슈 #72). 그래서 판의
    /// 모양·자리·전환·제스처를 전부 우리가 소유하는 오버레이로 바꿨다 — DS 안에 시스템 시트는 없다.
    ///
    /// **DS 가 시트 크롬을 갖는다** — 딤·자리·드래그·그래버·폭·모서리 0 이 여기 몫이고, 호출부는
    /// 판 색(`surface`)과 본문만 준다. 예전처럼 «껍데기만» 주고 판을 호출부가 그리던 계약은 시트 룩이
    /// 화면마다 갈라지는 원인이라 접었다.
    ///
    /// ```swift
    /// .hilitBottomSheet(
    ///     item: store.presentedDocument,
    ///     detents: [662.0 / 812.0, 1],          // 시안 높이로 열리고 위로 끌면 꽉 참
    ///     onDismiss: { send(.userDismissedDocument) }
    /// ) { item in
    ///     documentBody(item)                     // 본문만 — 배경·그래버·여백 위쪽은 DS 가 그린다
    /// }
    /// ```
    ///
    /// **값 기반** — `.hilitModal` 과 같은 계약. 스스로 닫지 않고, 사용자가 내린 것(딤 탭·아래로 끌기)만
    /// `onDismiss` 로 리듀서에 되돌린다. 판이 다 내려간 뒤에 불린다.
    ///
    /// 표출 층은 `.hilitModal` 과 같은 `fullScreenCover` — 네비바는 시스템 UIKit 바라 뷰 안쪽
    /// `overlay` 로는 딤이 바 밑에 깔려 X 만 환하게 남는다(`HilitModalPresenter` 주석). 따라오는 제약도
    /// 같다: **한 화면에 두 번 붙이지 않는다**(둘째 cover 가 조용히 무시됨 — 시트 2개↑ 는 `item:` 에 enum 하나).
    ///
    /// - Parameters:
    ///   - isPresented: 표출 여부.
    ///   - detents: 시트가 설 자리 — 화면 높이 대비 비율의 **오름차순** 배열. 시트는 가장 작은 자리로
    ///     열리고 드래그로 나머지를 오간다. 원소가 하나면 고정 높이 시트(아래로 끌기 = 닫기).
    ///   - surface: 판 색. 시안이 다크 시트를 쓰면 `Color.HilitBlack.b900`.
    ///   - showsGrabber: 머리 손잡이 표시. 끄면 드래그 판정도 함께 사라진다 — 닫는 길이 딤 탭뿐인
    ///     시트에만 쓴다.
    ///   - onDismiss: 사용자가 판을 내렸을 때 호출.
    func hilitBottomSheet<Content: View>(
        isPresented: Bool,
        detents: [CGFloat],
        surface: Color = Color.BlackWhite.white,
        showsGrabber: Bool = true,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(HilitBottomSheetPresenter(
            sheet: isPresented ? content() : nil,
            detents: detents,
            surface: surface,
            showsGrabber: showsGrabber,
            onDismiss: onDismiss
        ))
    }

    /// `hilitBottomSheet(isPresented:…)` 의 값 변형 — 표출 여부와 내용을 값 하나가 함께 정한다.
    /// 한 화면에 시트가 2개 이상일 때 Bool 여러 개 대신 enum 하나를 물려 동시 표출을 타입으로 차단한다.
    /// (`.hilitModal(item:)` 과 동일 패턴)
    ///
    /// ```swift
    /// .hilitBottomSheet(item: presentedSheet, detents: [0.5], onDismiss: { … }) { sheet in
    ///     switch sheet { case .filter: …; case .sort: … }
    /// }
    /// ```
    func hilitBottomSheet<Item: Equatable, Content: View>(
        item: Item?,
        detents: [CGFloat],
        surface: Color = Color.BlackWhite.white,
        showsGrabber: Bool = true,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: (Item) -> Content
    ) -> some View {
        modifier(HilitBottomSheetPresenter(
            sheet: item.map { content($0) },
            detents: detents,
            surface: surface,
            showsGrabber: showsGrabber,
            onDismiss: onDismiss
        ))
    }
}

/// 판 움직임의 규격 — 표출 층과 제스처가 같은 값을 보게 한곳에 둔다.
// TODO: 모션 시안 수령 후 임계값·곡선 확정 (지금 값은 구현자 판단 — 시안 근거 없음).
enum HilitBottomSheetMotion {
    /// 가장 작은 자리에서 이만큼 더 내리면 닫는다(pt). 44(터치 최소 크기)보다 크게 잡아 탭 흔들림과 갈라진다.
    static let dismissThreshold: CGFloat = 60
    /// 드래그로 인정하는 최소 이동 — 이보다 작으면 탭이다.
    static let minimumDragDistance: CGFloat = 10
    /// 등장·퇴장·자리 이동에 공통으로 쓰는 곡선.
    static let slide: Animation = .snappy(duration: 0.3, extraBounce: 0.05)
    /// 가장 큰 자리보다 더 위로 끌었을 때 따라가는 비율의 역수 — 저항만 주고 손을 떼면 되돌아온다.
    static let overshootResistance: CGFloat = 4
    /// 착지 판정에 얹는 관성 비율(0 = 관성 무시, 1 = `predictedEndTranslation` 그대로).
    /// 1 이면 살짝 튕기기만 해도 닫혀서 «조금 내렸는데 사라진다» 가 된다.
    static let velocityAssist: CGFloat = 0.1
}

/// 표출 배관 — 두 변형이 공유한다. 시트가 `nil` 이면 안 뜬다.
/// cover 를 쓰는 이유·제약은 `HilitModalPresenter` 와 동일(네비바 위 표출, 화면당 하나).
/// cover 기본 슬라이드업은 끄고(`disablesAnimations`) 전환은 안쪽 층이 직접 만든다 —
/// 전면 딤이 아래에서 밀려 올라오면 시안의 페이드와 다른 물건이 된다.
private struct HilitBottomSheetPresenter<Sheet: View>: ViewModifier {
    let sheet: Sheet?
    let detents: [CGFloat]
    let surface: Color
    let showsGrabber: Bool
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            Color.clear
                .allowsHitTesting(false)
                .fullScreenCover(isPresented: .init(get: { sheet != nil }, set: { _ in })) {
                    Group {
                        if let sheet {
                            HilitBottomSheetLayer(
                                detents: detents,
                                surface: surface,
                                showsGrabber: showsGrabber,
                                onDismiss: onDismiss
                            ) { sheet }
                        }
                    }
                    // cover 자체 배경만 지운다 — 딤은 안쪽 층이 그린다.
                    .presentationBackground(.clear)
                }
                .transaction { $0.disablesAnimations = true }
        }
    }
}

/// 딤 + 바닥 판 열 — cover 안에서 그려진다.
private struct HilitBottomSheetLayer<Sheet: View>: View {
    let detents: [CGFloat]
    let surface: Color
    let showsGrabber: Bool
    let onDismiss: () -> Void
    @ViewBuilder var sheet: Sheet

    /// 등장·퇴장 진행 — cover 자체 전환을 껐으므로 딤 페이드·판 슬라이드를 여기서 만든다.
    @State private var isOpen = false
    /// 지금 선 자리 — `detents` 의 인덱스. 시트는 가장 작은 자리(0)로 열린다.
    @State private var detentIndex = 0
    /// 끄는 중인 손가락 이동량(아래가 +). 손을 떼면 0 이거나 판이 통째로 내려간다.
    @State private var drag: CGFloat = 0

    /// 빈 배열이 오면 «꽉 참» 하나로 본다 — 자리 없는 시트는 성립하지 않는다.
    private var stops: [CGFloat] {
        detents.isEmpty ? [1] : detents
    }

    var body: some View {
        GeometryReader { proxy in
            // 시안 비율은 «화면» 기준이라 안전영역을 되더해 잰다 — proxy 는 그 안쪽만 준다.
            let bottomInset = proxy.safeAreaInsets.bottom
            let screenHeight = proxy.size.height + proxy.safeAreaInsets.top + bottomInset
            let layout = PanelLayout(screenHeight: screenHeight, stops: stops, index: detentIndex, drag: drag)

            ZStack(alignment: .bottom) {
                dim
                panel(screenHeight: screenHeight)
                    // 판 배경이 홈 인디케이터 자리까지 내려가므로 프레임은 그만큼 짧다(둘의 합이 시안 높이).
                    .frame(height: max(layout.height - bottomInset, 0))
                    .offset(y: isOpen ? layout.offset : layout.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // 오름차순 전제 — stops[0] 이 «가장 작은 자리»여야 닫기 판정이 성립한다.
            assert(stops == stops.sorted(), "hilitBottomSheet detents 는 오름차순이어야 한다: \(stops)")
            withAnimation(HilitBottomSheetMotion.slide) { isOpen = true }
        }
    }

    private var dim: some View {
        HilitDim.color
            .ignoresSafeArea()
            .opacity(isOpen ? 1 : 0)
            .onTapGesture(perform: dismiss)
    }

    /// 판 — 그래버 + 본문. 배경색은 홈 인디케이터 자리까지 내려간다.
    /// 착지 판정에 화면 높이가 필요해 제스처까지 여기서 엮는다(높이는 `GeometryReader` 안에서만 잰다).
    private func panel(screenHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            if showsGrabber {
                SheetGrabber()
                    .gesture(dragGesture(screenHeight: screenHeight))
            }
            sheet
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(surface.ignoresSafeArea(edges: .bottom))
    }

    /// 좌표계는 **global** — 손잡이는 드래그를 따라 움직이는 뷰라, 기본(local)로 재면 판이 Δ 내려갈 때
    /// 좌표계도 같이 내려가 translation 이 되감기고, 그 값이 판을 도로 올리는 피드백 루프로 떨린다.
    private func dragGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: HilitBottomSheetMotion.minimumDragDistance, coordinateSpace: .global)
            .onChanged { drag = $0.translation.height }
            .onEnded { value in
                // 관성을 그대로 쓰면 살짝 튕기기만 해도 예상 종료가 임계값을 넘는다 —
                // 손가락이 실제로 간 거리를 기준으로 삼고 속도는 보조로만 얹는다.
                let actual = value.translation.height
                let inertia = value.predictedEndTranslation.height - actual
                settle(
                    travel: actual + inertia * HilitBottomSheetMotion.velocityAssist,
                    screenHeight: screenHeight
                )
            }
    }

    /// 손을 뗀 뒤 착지 — 끌린 만큼 줄어든 높이에 가장 가까운 자리로 붙고,
    /// 가장 작은 자리보다 임계값 이상 더 내려갔으면 닫는다.
    private func settle(travel: CGFloat, screenHeight: CGFloat) {
        let stops = self.stops
        let current = stops.indices.contains(detentIndex) ? stops[detentIndex] : stops[0]
        let projected = screenHeight * current - travel

        guard projected >= screenHeight * stops[0] - HilitBottomSheetMotion.dismissThreshold else {
            dismiss()
            return
        }
        let nearest = stops.indices.min {
            abs(screenHeight * stops[$0] - projected) < abs(screenHeight * stops[$1] - projected)
        }
        withAnimation(HilitBottomSheetMotion.slide) {
            detentIndex = nearest ?? detentIndex
            drag = 0
        }
    }

    private func dismiss() {
        guard isOpen else { return }
        withAnimation(HilitBottomSheetMotion.slide) {
            isOpen = false
            drag = 0
        } completion: {
            onDismiss()
        }
    }
}

/// 끄는 중 판의 높이·오프셋 — 위로 끌면 판이 «자라고», 아래로 끌면 판이 «내려간다».
/// 어느 쪽이든 판 윗변이 손가락을 그대로 따라오고 아랫변은 화면 바닥에 붙어 있는다.
private struct PanelLayout {
    let height: CGFloat
    let offset: CGFloat

    init(screenHeight: CGFloat, stops: [CGFloat], index: Int, drag: CGFloat) {
        let base = screenHeight * (stops.indices.contains(index) ? stops[index] : 1)
        let ceiling = screenHeight * (stops.last ?? 1)

        // 아래로(+) 끌면 높이는 그대로 두고 판째 내린다 — 줄이면 본문이 다시 흐르며 덜컹거린다.
        offset = max(drag, 0)

        // 위로(−) 끌면 자란다. 가장 큰 자리를 넘어서는 몫은 저항만 준다(자리가 없으므로).
        let grown = base - min(drag, 0)
        height = grown <= ceiling
            ? grown
            : ceiling + (grown - ceiling) / HilitBottomSheetMotion.overshootResistance
    }
}

// MARK: - Previews

#Preview("자리 둘 — 시안 높이 ↔ 꽉 참") {
    @Previewable @State var isPresented = true
    Button("시트 열기") { isPresented = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hilitBottomSheet(
            isPresented: isPresented,
            detents: [662.0 / 812.0, 1],
            onDismiss: { isPresented = false },
            content: {
                VStack(alignment: .leading, spacing: .ds(.p12)) {
                    Text("서비스 이용 약관")
                        .dsTypography(.sub7)
                    ScrollView {
                        Text(String(repeating: "본문 ", count: 400))
                            .dsTypography(.body4)
                    }
                }
                .padding(.horizontal, .ds(.p20))
            }
        )
}

/// 분기 프리뷰용 — result builder 안에선 타입 선언이 안 돼 파일 스코프에 둔다.
private enum PreviewSheet: Equatable {
    case filter
    case sort
}

#Preview("자리 하나 — 시트 2개 분기") {
    @Previewable @State var presented: PreviewSheet? = .filter
    VStack(spacing: 12) {
        Button("필터") { presented = .filter }
        Button("정렬") { presented = .sort }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .hilitBottomSheet(
        item: presented,
        detents: [0.4],
        onDismiss: { presented = nil },
        content: { sheet in
            VStack(spacing: .ds(.p20)) {
                switch sheet {
                case .filter:
                    Text("필터").dsTypography(.sub1)
                case .sort:
                    Text("정렬").dsTypography(.sub1)
                }
                ButtonLarge("닫기", .modal) { presented = nil }
            }
            .padding(.ds(.p24))
        }
    )
}
