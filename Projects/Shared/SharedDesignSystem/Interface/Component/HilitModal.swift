//
//  HilitModal.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «modal» 딤 — https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=2302-6080

import SwiftUI

public extension View {
    /// 모달 오버레이 — 딤(블랙 60%) 위에 카드를 중앙 표출한다.
    /// 카드는 아무 뷰 — 시안의 세 모달 계열 `Modal`·`HomeModal`·`LoadingModal` 이 전부 이걸로 올라온다.
    ///
    /// ```swift
    /// .hilitModal(isPresented: store.isExitConfirmPresented) {
    ///     Modal("정말 나가시겠어요?") { ButtonLarge("확인", .modal) { send(.userTappedConfirm) } }
    /// }
    /// ```
    ///
    /// **값 기반·읽기 전용** — 스스로 닫지 않는다. 닫힘은 카드 버튼 클로저가 리듀서 액션으로 보내
    /// 상태를 내리는 것(딤 탭 dismiss 없음 — 시안·현행 UX 에 없어서. 생기면 리듀서 액션 클로저로 추가).
    /// Binding 을 받지 않는 이유: 쓰기 경로가 없는데 Binding 을 받으면 API 가 거짓말을 한다.
    ///
    /// 카드 좌우 여백 px24 를 여기서 준다(시안 327 = 화면 375 − 24×2) — 카드는 폭을 정하지 않는다.
    /// 시안의 backdrop blur 40 은 미포함 — 필요하면 호출부가 배경 콘텐츠 블러로 근사한다(InterviewSession 참조).
    func hilitModal<Content: View>(
        isPresented: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        overlay {
            if isPresented {
                HilitModalLayer { content() }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }

    /// `hilitModal(isPresented:content:)` 의 분기 변형 — 한 화면에 모달이 2개 이상일 때
    /// Bool 여러 개 대신 enum 하나를 물려 동시 표출을 타입으로 차단한다.
    ///
    /// ```swift
    /// .hilitModal(item: presentedModal) { modal in
    ///     switch modal { case .exitConfirm: …; case .earlyExitWarning: … }
    /// }
    /// ```
    func hilitModal<Item: Equatable, Content: View>(
        item: Item?,
        @ViewBuilder content: (Item) -> Content
    ) -> some View {
        overlay {
            if let item {
                HilitModalLayer { content(item) }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: item)
    }
}

/// Figma 딤 실측 블랙 60% — 대응 색 토큰 없음(디자인 변수 미정의), 리터럴은 여기 한 곳만.
/// `.hilitModal`(중앙 카드)과 `.hilitBottomSheet`(바닥 시트)가 공유한다.
enum HilitDim {
    static let color = Color.black.opacity(0.6)
}

/// 딤 + 중앙 카드 열 — 두 변형이 공유하는 레이어.
private struct HilitModalLayer<Card: View>: View {
    @ViewBuilder var card: Card

    var body: some View {
        ZStack {
            HilitDim.color
                .ignoresSafeArea()
            card
                .padding(.horizontal, .ds(.p24))
        }
    }
}

// MARK: - Previews

#Preview("Bool — Modal 카드") {
    @Previewable @State var isPresented = true
    Button("모달 열기") { isPresented = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hilitModal(isPresented: isPresented) {
            Modal("정말 나가시겠어요?") {
                ButtonLarge(.modal, tone: .twoColor) {
                    Button("취소") { isPresented = false }
                } trailing: {
                    Button("나가기") { isPresented = false }
                }
            }
        }
}

#Preview("Bool — HomeModal 카드") {
    Color.GrayScale.g50
        .ignoresSafeArea()
        .hilitModal(isPresented: true) {
            HomeModal(
                "title",
                subTitle: "sub-title",
                icon: Image.Img.oppO,
                info: "텍스트를 입력해주세요"
            )
        }
}

#Preview("Bool — LoadingModal 카드") {
    Color.GrayScale.g50
        .ignoresSafeArea()
        .hilitModal(isPresented: true) {
            LoadingModal()
        }
}

/// 분기 프리뷰용 — result builder 안에선 타입 선언이 안 돼 파일 스코프에 둔다.
private enum PreviewModal: Equatable {
    case exitConfirm
    case earlyExitWarning
}

#Preview("Item — 팝업 2개 분기") {
    @Previewable @State var presented: PreviewModal? = .exitConfirm
    VStack(spacing: 12) {
        Button("종료 확인") { presented = .exitConfirm }
        Button("이탈 경고") { presented = .earlyExitWarning }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .hilitModal(item: presented) { modal in
        switch modal {
        case .exitConfirm:
            Modal("면접을 마칠까요?") {
                ButtonLarge("계속하기", .modal) { presented = nil }
            }
        case .earlyExitWarning:
            Modal("지금 나가면 이용권 1회가 차감돼요") {
                ButtonLarge("나가기", .modal) { presented = nil }
            }
        }
    }
}
