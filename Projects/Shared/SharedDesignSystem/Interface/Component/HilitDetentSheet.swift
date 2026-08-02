//
//  HilitDetentSheet.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/08/02.
//

import SwiftUI

public extension View {
    /// detent 바텀시트 — **시스템 `.sheet`** 을 그대로 쓴다. 드래그로 높이 조절, 아래로 스와이프 닫기,
    /// 스크롤 맨 위에서 이어지는 시트 확장·축소가 전부 시스템 몫이다.
    ///
    /// 오버레이 껍데기(`.hilitBottomSheet`)와의 갈림길: **높이가 바뀌는 시트면 이걸 쓴다.**
    /// 오버레이는 고정 높이 + 딤 탭 닫기만 되는 판이라 제스처를 흉내내야 하고, 시스템 시트는
    /// detent 를 넘기면 그게 공짜로 온다. 고정 높이 시트나 화면 안에 상주하는 시트(홈 리포트 판)는
    /// 계속 오버레이 쪽.
    ///
    /// ```swift
    /// .hilitDetentSheet(
    ///     item: store.presentedDocument,
    ///     detents: [.fraction(0.8), .large],
    ///     onDismiss: { send(.userDismissedDocument) }
    /// ) { item in
    ///     sheetBody(item)
    ///         .presentationBackground(Color.BlackWhite.white)
    /// }
    /// ```
    ///
    /// **값 기반** — `.hilitBottomSheet`·`.hilitModal` 과 같은 계약. 상태는 리듀서가 소유하고,
    /// 시스템이 닫은 것(스와이프·딤 탭)만 `onDismiss` 로 리듀서에 되돌린다.
    ///
    /// 판 배경은 호출부가 `.presentationBackground(…)` 로 준다 — 시트마다 색이 달라서. 그래버는
    /// 시안 규격(60×5 g400)이 시스템 인디케이터와 달라 숨기고, 필요하면 호출부가 직접 그린다.
    ///
    /// - Parameters:
    ///   - item: 표출할 값 — nil 이면 닫힘. `Identifiable` 이라 바뀌면 시트 내용도 갈린다.
    ///   - detents: 허용 높이들. 시트는 그중 가장 작은 것으로 열리고, 드래그로 나머지를 오간다.
    ///   - cornerRadius: 시트 상단 코너 — 기본 0 (DS 전반의 «모서리 0»).
    ///   - onDismiss: 시스템이 시트를 닫았을 때 호출 — 보통 닫기 리듀서 액션.
    func hilitDetentSheet<Item: Identifiable & Equatable, Content: View>(
        item: Item?,
        detents: Set<PresentationDetent>,
        cornerRadius: CGFloat = 0,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        // 시스템 sheet 는 쓰기 경로(스와이프 닫기)가 필요해 Binding 을 받는다 — set 의 nil 만
        // 의미가 있고(사용자가 닫음), 여는 쪽은 상태(item)가 단독으로 정한다.
        let binding = Binding(
            get: { item },
            set: { if $0 == nil { onDismiss() } }
        )
        return sheet(item: binding) { value in
            content(value)
                .presentationDetents(detents)
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(cornerRadius)
        }
    }
}

// MARK: - Previews

/// 프리뷰용 표출 값 — 실제로는 도메인 모델(약관 항목 등)이 들어온다.
private struct PreviewDocument: Identifiable, Equatable {
    let id: String
    let title: String
}

#Preview("detent 시트 — 0.8 ↔ large") {
    @Previewable @State var document: PreviewDocument? = PreviewDocument(id: "terms", title: "서비스 이용 약관")
    Button("시트 열기") { document = PreviewDocument(id: "terms", title: "서비스 이용 약관") }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hilitDetentSheet(
            item: document,
            detents: [.fraction(0.8), .large],
            onDismiss: { document = nil }
        ) { value in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.GrayScale.g400)
                    .frame(width: 60, height: 5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                Text(value.title)
                    .dsTypography(.sub7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .ds(.p20))
                ScrollView {
                    Text(String(repeating: "본문 ", count: 400))
                        .dsTypography(.body4)
                        .padding(.horizontal, .ds(.p20))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .presentationBackground(Color.BlackWhite.white)
        }
}
