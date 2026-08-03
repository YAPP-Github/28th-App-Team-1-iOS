//
//  HilitBottomSheet.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

import SwiftUI

public extension View {
    /// 바텀시트 오버레이 — 딤(블랙 60%, `.hilitModal` 과 동일) 위에 시트를 화면 바닥에 표출한다.
    /// **껍데기만 제공** — 딤·바닥 정렬·슬라이드 전환이 전부이고, 시트의 판(배경·상단 코너·패딩)은
    /// 호출부가 그린다. 화면마다 다른 커스텀 시트가 실재해서 카드를 표준화하지 않는다.
    ///
    /// ```swift
    /// .hilitBottomSheet(isPresented: store.isFilterPresented) {
    ///     VStack(spacing: .ds(.p20)) { … }
    ///         .padding(.ds(.p24))
    ///         .frame(maxWidth: .infinity)
    ///         .background {
    ///             UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
    ///                 .fill(Color.BlackWhite.white)
    ///                 .ignoresSafeArea(edges: .bottom)   // 판만 홈 인디케이터 아래까지
    ///         }
    /// }
    /// ```
    ///
    /// **값 기반·읽기 전용** — `.hilitModal` 과 같은 계약. 스스로 닫지 않고, 닫힘은 시트 버튼이나
    /// `onDimTap` 클로저가 리듀서 액션을 보내 상태를 내리는 것. Binding 을 받지 않는 이유도 동일 —
    /// 쓰기 경로가 없는데 Binding 을 받으면 API 가 거짓말을 한다.
    ///
    /// 시트 위치는 safe area 바닥(홈 인디케이터 위) — 판을 그 아래까지 깔려면 위 예시처럼
    /// 배경 shape 에 `.ignoresSafeArea(edges: .bottom)`.
    ///
    /// **드래그 없음 — 고정 높이 시트 전용.** 높이가 드래그로 바뀌어야 하면 `.hilitDetentSheet`
    /// (시스템 `.sheet` + detent)를 쓴다. 오버레이로 제스처를 흉내내지 않는다.
    ///
    /// 표출은 `.hilitModal` 과 같은 `fullScreenCover` 다 — 네비바(시스템 UIKit 바)까지 덮어야 하므로.
    /// 따라오는 제약도 같다: **한 화면에 두 번 붙이지 않는다**(둘째 cover 가 조용히 무시됨 — 시트
    /// 2개↑ 는 `item:` 에 enum 하나), 닫힘 전환은 즉시. 이유는 `HilitModalPresenter` 주석.
    ///
    /// - Parameter onDimTap: 딤 탭 시 호출 — 보통 닫기 리듀서 액션. `nil`(기본)이면 딤 탭 무시.
    func hilitBottomSheet<Content: View>(
        isPresented: Bool,
        onDimTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(HilitBottomSheetPresenter(
            sheet: isPresented ? content() : nil,
            onDimTap: onDimTap
        ))
    }

    /// `hilitBottomSheet(isPresented:onDimTap:content:)` 의 분기 변형 — 한 화면에 시트가 2개 이상일 때
    /// Bool 여러 개 대신 enum 하나를 물려 동시 표출을 타입으로 차단한다. (`.hilitModal(item:)` 과 동일 패턴)
    ///
    /// ```swift
    /// .hilitBottomSheet(item: presentedSheet) { sheet in
    ///     switch sheet { case .filter: …; case .sort: … }
    /// }
    /// ```
    func hilitBottomSheet<Item: Equatable, Content: View>(
        item: Item?,
        onDimTap: (() -> Void)? = nil,
        @ViewBuilder content: (Item) -> Content
    ) -> some View {
        modifier(HilitBottomSheetPresenter(
            sheet: item.map { content($0) },
            onDimTap: onDimTap
        ))
    }
}

/// 표출 배관 — 두 변형이 공유한다. 시트가 `nil` 이면 안 뜬다.
/// cover 를 쓰는 이유·제약은 `HilitModalPresenter` 와 동일(네비바 위 표출, 화면당 하나, 닫힘 즉시).
/// 슬라이드업(0.25)은 cover 기본 전환이 아니라 레이어가 직접 만든다 — 시스템 전환은 껐다.
private struct HilitBottomSheetPresenter<Sheet: View>: ViewModifier {
    let sheet: Sheet?
    var onDimTap: (() -> Void)?

    func body(content: Content) -> some View {
        content.overlay {
            Color.clear
                .allowsHitTesting(false)
                .fullScreenCover(isPresented: .init(get: { sheet != nil }, set: { _ in })) {
                    HilitBottomSheetLayer(onDimTap: onDimTap) { sheet }
                        .presentationBackground(.clear)
                }
                .transaction { $0.disablesAnimations = true }
        }
    }
}

/// 딤 + 바닥 시트 열 — cover 안에서 그려진다.
private struct HilitBottomSheetLayer<Sheet: View>: View {
    var onDimTap: (() -> Void)?
    @ViewBuilder var sheet: Sheet

    /// 표출 전환용 — cover 자체 전환을 껐으므로 딤 페이드·시트 슬라이드를 여기서 만든다.
    @State private var isVisible = false

    var body: some View {
        ZStack(alignment: .bottom) {
            HilitDim.color
                .ignoresSafeArea()
                .opacity(isVisible ? 1 : 0)
                .onTapGesture { onDimTap?() }
            if isVisible {
                sheet
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) { isVisible = true }
        }
    }
}

// MARK: - Previews

#Preview("Bool — 커스텀 시트") {
    @Previewable @State var isPresented = true
    Button("시트 열기") { isPresented = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hilitBottomSheet(isPresented: isPresented, onDimTap: { isPresented = false }) {
            VStack(spacing: .ds(.p20)) {
                Text("정렬 기준")
                    .dsTypography(.sub1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: .ds(.p12)) {
                    Text("최신순").dsTypography(.body2)
                    Text("오래된순").dsTypography(.body2)
                }
                ButtonLarge("확인", .modal) { isPresented = false }
            }
            .padding(.ds(.p24))
            .frame(maxWidth: .infinity)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                    .fill(Color.BlackWhite.white)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
}

/// 분기 프리뷰용 — result builder 안에선 타입 선언이 안 돼 파일 스코프에 둔다.
private enum PreviewSheet: Equatable {
    case filter
    case sort
}

#Preview("Item — 시트 2개 분기") {
    @Previewable @State var presented: PreviewSheet? = .filter
    VStack(spacing: 12) {
        Button("필터") { presented = .filter }
        Button("정렬") { presented = .sort }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .hilitBottomSheet(item: presented, onDimTap: { presented = nil }) { sheet in
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
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(Color.BlackWhite.white)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
