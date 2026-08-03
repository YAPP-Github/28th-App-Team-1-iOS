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
    /// 표출은 `overlay` 라 **딤이 시스템 네비바 밑에 깔린다** — 네비바가 있는 화면에서 쓰려면
    /// `.hilitModal` 처럼 presentation(cover) 기반으로 바꿔야 한다(현재 호출부 없음).
    ///
    /// - Parameter onDimTap: 딤 탭 시 호출 — 보통 닫기 리듀서 액션. `nil`(기본)이면 딤 탭 무시.
    func hilitBottomSheet<Content: View>(
        isPresented: Bool,
        onDimTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        overlay {
            if isPresented {
                HilitBottomSheetLayer(onDimTap: onDimTap) { content() }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
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
        overlay {
            if let item {
                HilitBottomSheetLayer(onDimTap: onDimTap) { content(item) }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: item)
    }
}

/// 딤 + 바닥 시트 열 — 두 변형이 공유하는 레이어.
private struct HilitBottomSheetLayer<Sheet: View>: View {
    var onDimTap: (() -> Void)?
    @ViewBuilder var sheet: Sheet

    var body: some View {
        ZStack(alignment: .bottom) {
            HilitDim.color
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture { onDimTap?() }
            sheet
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom))
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
