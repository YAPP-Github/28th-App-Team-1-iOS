//
//  AxisCommentCard.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import SharedDesignSystemInterface
import SwiftUI

/// "왜 그렇게 느꼈나요?" 펼침 코멘트 입력 카드 — 평가 화면 하단 흰 시트로 뜬다.
/// Figma «text-field/large-with-cta»(node 1984:6994) + 하단 black CTA(다음) 1:1 —
/// 헤더(질문 + "선택" 태그 + 닫기) · 여러 줄 입력 · 풀폭 검정 «다음» 버튼.
struct AxisCommentCard: View {
    @Binding var text: String
    let onDone: () -> Void
    let onDismiss: () -> Void

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
                .dsTypography(.body7)  // Regular 14
                .foregroundStyle(Color.ds(.black800))
                .lineLimit(3...6)
                .frame(minHeight: 90, alignment: .topLeading)
            }
            .padding(.horizontal, .ds(.p24))
            .padding(.vertical, .ds(.p14))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ds(.white))

            PrimaryButton("다음", action: onDone)
        }
    }

    private var header: some View {
        HStack(spacing: .ds(.p4)) {
            Text("왜 그렇게 느꼈나요?")
                .dsTypography(.body5)  // SemiBold 14
                .foregroundStyle(Color.ds(.black800))
            optionalTag
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.ds(.body5))
                    .foregroundStyle(Color.ds(.gray600))
            }
            .buttonStyle(.plain)
        }
    }

    /// 선택 입력임을 알리는 회색 태그 — Figma tag(gray/100 bg · gray/600 text).
    private var optionalTag: some View {
        Text("선택")
            .dsTypography(.body8)  // SemiBold 12
            .foregroundStyle(Color.ds(.gray600))
            .padding(.horizontal, .ds(.p4))
            .background(Color.dsSeparator)
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
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .background(Color.dsBgDark)  // 영상 위 시트 시뮬레이션
}
