//
//  AxisCommentCard.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import SharedDesignSystemInterface
import SwiftUI

/// "왜 그렇게 느꼈나요?" 펼침 코멘트 입력 카드 — 키보드 위에 뜨는 플로팅 아일랜드.
/// Figma «text-field/large-with-cta»(node 1984:6994) + 모달 CTA «다음»(button-large/modal, node 2302:5985) —
/// 헤더(질문 + "선택" 태그 + 닫기) · 여러 줄 입력(최대 5줄, «[4] 서술형 - 5줄») · 풀폭 검정 버튼.
/// CTA 는 PrimaryButton(하단 도킹 전용 — 배경이 키보드·세이프에어리어까지 번짐)이 아니라
/// 대칭 py16·번짐 없는 모달 변형이라 로컬로 그린다. 등장 즉시 포커스해 키보드 위 도킹으로 시작한다.
struct AxisCommentCard: View {
    @Binding var text: String
    let onDone: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        onDone: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._text = text
        self.onDone = onDone
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                header
                TextField(
                    "느낀 그대로를 작성해주면 더 도움이 돼요.",
                    text: $text,
                    axis: .vertical
                )
                .focused($isFocused)
                .dsTypography(.body7)  // Regular 14
                .foregroundStyle(Color.HilitBlack.b800)
                .lineLimit(3...5)
                .frame(minHeight: 90, alignment: .topLeading)
            }
            .padding(.horizontal, .ds(.p24))
            .padding(.vertical, .ds(.p16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.BlackWhite.white)

            doneButton
        }
        .onAppear { isFocused = true }
    }

    /// Figma button-large/modal — b800 배경 · sub7(SemiBold 18) 흰 텍스트 · py16 대칭(높이 55).
    private var doneButton: some View {
        Button(action: onDone) {
            Text("다음")
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .ds(.p16))
                .background(Color.HilitBlack.b800)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: .ds(.p4)) {
            Text("왜 그렇게 느꼈나요?")
                .dsTypography(.body5)  // SemiBold 14
                .foregroundStyle(Color.HilitBlack.b800)
            optionalTag
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.ds(.body5))
                    .foregroundStyle(Color.Gray.g600)
            }
            .buttonStyle(.plain)
        }
    }

    /// 선택 입력임을 알리는 회색 태그 — Figma tag(gray/100 bg · gray/600 text).
    private var optionalTag: some View {
        Text("선택")
            .dsTypography(.body8)  // SemiBold 12
            .foregroundStyle(Color.Gray.g600)
            .padding(.horizontal, .ds(.p4))
            .background(Color.Gray.g100)
    }
}

#Preview {
    VStack(spacing: .ds(.p24)) {
        AxisCommentCard(text: .constant(""), onDone: {}, onDismiss: {})  // placeholder 상태
        AxisCommentCard(
            text: .constant("시선을 잘 마주쳐서 대화가 편안했어요."),
            onDone: {},
            onDismiss: {}
        )  // 입력됨
    }
    .padding(.horizontal, .ds(.p20))   // 오버레이 아일랜드 여백 재현
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .background(Color.HilitBlack.b800)  // 영상 위 오버레이 시뮬레이션
}
