//
//  GuestOnboardingView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI

// @lat: [[feedback#G4 게스트 평가]]
/// 지인 피드백 온보딩 메인(Figma `Peerfeedback_onboarding1`, node 1855:8498).
/// 흰 배경 — DS TitleBox(그린 마커 "피드백") + 히어로 일러스트 밴드(`Img.feedback`, 하단 화이트 페이드) +
/// 안내 2행(`Img.person`·`Img.talk` 타일) + 하단 블랙 CTA. 닉네임 입력은 다음 스텝(GuestNicknameView).
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestOnboardingView: View {
    let store: StoreOf<GuestFeedbackFeature>

    private var requesterName: String { store.entry?.requesterName ?? "지원자" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TitleBox(
                [
                    TitleBox.Line("\(requesterName)님이 당신께"),
                    TitleBox.Line("피드백을 요청했어요", highlight: "피드백")
                ],
                sub: "이동 시간 중 딱 10분만 빌려줄 수 있나요?"
            )
            .padding(.horizontal, .ds(.p20))
            // @ds(spacing): 34 — 상태바~타이틀 (Figma title-box y77, 토큰 없음)
            .padding(.top, 34)

            illustrationBand
                .padding(.top, .ds(.p16))

            guideRows
                // @ds(layout): -41 — 안내 행이 밴드 하단 페이드 위로 겹친다 (Figma 행 y547, 밴드 끝 588)
                .padding(.top, -41)

            Spacer(minLength: .ds(.p24))
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.BlackWhite.white.ignoresSafeArea())
    }

    // MARK: - Illustration band

    /// 히어로 일러스트 밴드 — 회색 판 위 `feedback/214px`, 하단은 흰색으로 페이드 (Figma 3683:9109 + 1855:8516).
    private var illustrationBand: some View {
        Image.Img.feedback   // 214pt — 디자인된 크기 그대로 (design/image.md 리사이즈 금지)
            .frame(maxWidth: .infinity)
            // @ds(spacing): 60/132 — 밴드 안 일러스트 상/하 여백 (spacing 토큰은 4~24 뿐)
            .padding(.top, 60)
            .padding(.bottom, 132)
            .background {
                // @ds(color): #F3F4F6 → GrayScale.g50 — 일러스트 밴드 판 (팔레트 밖 값, g50 로 근사)
                // @ds(radius): 4 — 밴드 상단 모서리 (radius 토큰 없음)
                UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                    .fill(Color.GrayScale.g50)
            }
            .overlay(alignment: .bottom) {
                // @ds(layout): 167 — 밴드 하단 화이트 페이드 높이 (Figma 1855:8516)
                LinearGradient(
                    colors: [Color.BlackWhite.white.opacity(0), Color.BlackWhite.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 167)
                .allowsHitTesting(false)
            }
    }

    // MARK: - Guide rows

    private var guideRows: some View {
        // @ds(spacing): 40 — 행 사이·좌우 여백 (Figma 3683:11690, spacing 토큰은 4~24 뿐)
        VStack(alignment: .leading, spacing: 40) {
            guideRow(
                icon: Image.Img.person,
                title: "AI가 못 보는 것도 있어요",
                subtitle: "눈빛, 말투 같은 순간은 당신만 알아요"
            )
            guideRow(
                icon: Image.Img.talk,
                title: "면접은 외우기가 아니라 대화예요",
                subtitle: "정해진 답보다 얼마나 자연스러운지 봐주세요"
            )
        }
        .padding(.horizontal, 40)
    }

    private func guideRow(icon: Image, title: String, subtitle: String) -> some View {
        HStack(spacing: .ds(.p12)) {
            icon   // 40pt 타일 — 판·색까지 에셋에 구워진 원본 (Figma «onboarding text with graphic»)
            // @ds(spacing): 2 — 타이틀~서브 사이 (spacing 토큰은 4 부터)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dsTypography(.body2)
                    .foregroundStyle(Color.HilitBlack.b800)
                Text(subtitle)
                    .dsTypography(.body7)
                    .foregroundStyle(Color.GrayScale.g500)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Footer (CTA)

    private var footer: some View {
        ButtonLarge("피드백 시작하기", .bottom) {
            send(.startTapped)
        }
    }
}

#Preview {
    var state = GuestFeedbackFeature.State(token: "preview")
    state.phase = .onboarding
    state.entry = GuestFeedbackEntry(
        gate: .open,
        requesterName: "재원",
        axes: [],
        videoUrl: nil,
        questionBoundaries: [],
        submissionOpen: true
    )
    return GuestOnboardingView(
        store: Store(initialState: state) { GuestFeedbackFeature() }
    )
}
