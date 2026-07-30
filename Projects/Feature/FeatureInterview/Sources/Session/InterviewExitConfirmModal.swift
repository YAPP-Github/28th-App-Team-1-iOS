//
//  InterviewExitConfirmModal.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import SharedDesignSystemInterface
import SwiftUI

/// 면접 종료 확인 모달 카드 — Figma «modal»(2555:7739, 컴포넌트 2302:6080 계열) 1:1.
/// 폭 327 흰 카드(py40/px24 · 직각 모서리): 책 배지(74) + 타이틀/본문, 하단은 DS `ButtonLarge`
/// modal 2버튼(`.twoColor` — 계속하기 회색 · 마치기 검정).
/// 딤·표출 타이밍은 호출부 책임.
/// 문구는 부록 C 확정 — 종료 확인(기본값)과 중도 이탈 경고가 같은 카드를 쓴다.
struct InterviewExitConfirmModal: View {
    // 기본값 = 종료 확인 문구. 중도 이탈 경고가 memberwise init 으로 덮어쓰므로 var 유지.
    var title = "면접을 마칠까요?"
    var message: String? = "마치기를 클릭하는 즉시 면접이 종료됩니다.\n지금까지 답변으로 분석을 시작해요."
    var continueLabel = "계속하기"
    var finishLabel = "마치기"
    var onContinue: () -> Void
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
            // modal 2버튼 — 왼쪽 회색·오른쪽 검정 반반(`.twoColor`), 가로 px8 여백은 DS 가 준다.
            ButtonLarge(.modal, tone: .twoColor) {
                Button(continueLabel, action: onContinue)
            } trailing: {
                Button(finishLabel, action: onFinish)
            }
        }
        .frame(width: 327)
        .background(Color.BlackWhite.white)
    }

    private var content: some View {
        VStack(spacing: .ds(.p20)) {
            bookBadge
            VStack(spacing: .ds(.p4)) {
                Text(title)
                    .dsTypography(.sub4)
                    .foregroundStyle(Color.modalTitle)
                if let message {
                    Text(message)
                        .dsTypography(.body6)
                        .foregroundStyle(Color.GrayScale.g500)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, .ds(.p24))
        .padding(.vertical, 40)
    }

    /// Figma «book/74px»(1991:10173) — 그린 뒤판까지 한 장에 구워진 74 일러스트.
    private var bookBadge: some View {
        Image.Img.book
    }
}

private extension Color {
    /// 모달 타이틀 · #262A30 — Figma 변수(Gray scale/800)가 팔레트(g800 #31333B)와 어긋나는
    /// 미바인딩 계열 값이라 DS 토큰화 보류 (color.md 규칙, 디자이너 확인 필요).
    static let modalTitle = Color(red: 38 / 255, green: 42 / 255, blue: 48 / 255)
}

#Preview {
    InterviewExitConfirmModal(onContinue: {}, onFinish: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
}
