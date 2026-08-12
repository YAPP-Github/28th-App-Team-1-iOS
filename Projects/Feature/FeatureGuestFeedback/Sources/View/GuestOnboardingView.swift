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

// Figma: «Part4 지인피드백 / Peerfeedback_onboarding1» node 802:7431
// @lat: [[feedback#G4 게스트 평가]]
/// 지인 피드백 온보딩 메인.
/// 라이트 톤 — DS TitleBox(그린 마커 "피드백") + 히어로 일러스트 밴드(g50 판이 흰색으로 페이드) +
/// 안내 2행 + 하단 블랙 CTA. 상단 X 없음(시안), 닉네임 입력은 다음 스텝(GuestNicknameView).
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestOnboardingView: View {
    let store: StoreOf<GuestFeedbackFeature>

    private var requesterName: String { store.entry?.requesterName ?? "지원자" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBlock
                .padding(.horizontal, .ds(.p20))
                // @ds(spacing): 34 — 상태바(y43) 아래 title-box(y77) 까지
                .padding(.top, 34)

            illustration   // 풀블리드 — 양쪽 여백 없이 화면 폭 전체 (Figma node 802:7432, x0 w375)
                .padding(.top, .ds(.p16))

            guideRows
                .padding(.horizontal, .ds(.p40))

            Spacer(minLength: .ds(.p24))

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.BlackWhite.white.ignoresSafeArea())
    }

    // MARK: - Title

    /// DS TitleBox — Figma «title-box»(802:7438) 1:1: "{요청자}님이 당신께 / [피드백]을 요청했어요".
    private var titleBlock: some View {
        TitleBox(
            [
                TitleBox.Line("\(requesterName)님이 당신께"),
                TitleBox.Line("피드백을 요청했어요", highlight: "피드백")
            ],
            sub: "이동 시간 중 딱 10분만 빌려줄 수 있나요?"
        )
    }

    // MARK: - Illustration

    /// 히어로 일러스트 밴드 — Figma node 802:7432(g50 판) + 802:7436(하단 흰색 페이드).
    /// 일러스트는 214pt 로 그려진 에셋이라 리사이즈하지 않는다 (design/lessons.md 2번).
    /// 페이드가 판 바닥에서 정확히 흰색에 도달해 아래 안내 행 배경과 이어진다.
    private var illustration: some View {
        Image.Img.feedback
            .frame(maxWidth: .infinity)
            // @ds(spacing): 60 — 판 상단~일러스트 (Figma 802:7432 padding-top)
            .padding(.top, 60)
            // @ds(spacing): 91 — 일러스트 바닥(y456)~안내 행(y547)
            .padding(.bottom, 91)
            .background {
                Color.GrayScale.g50
                    .overlay(alignment: .bottom) {
                        // @ds(spacing): 167 — 페이드 높이 (Figma 802:7436 y421~588)
                        LinearGradient(
                            colors: [.clear, Color.BlackWhite.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 167)
                    }
            }
            // @ds(radius): 4 — 판 상단 모서리만 (Figma rounded-tl/tr 4)
            .clipShape(.rect(topLeadingRadius: 4, topTrailingRadius: 4))
    }

    // MARK: - Guide rows

    private var guideRows: some View {
        VStack(alignment: .leading, spacing: .ds(.p40)) {
            guideRow(
                icon: Image.Img.person,          // Figma icon1 = person/40px (435:656)
                title: "AI가 못 보는 것도 있어요",
                subtitle: "눈빛, 말투 같은 순간은 당신만 알아요"
            )
            guideRow(
                icon: Image.Img.talk,            // Figma icon2 = talk/40px (435:652)
                title: "면접은 외우기가 아니라 대화예요",
                subtitle: "정해진 답보다 얼마나 자연스러운지 봐주세요"
            )
        }
    }

    /// Figma «onboarding text with graphic»(439:10628) — 40×40 타일 + gap12 + 텍스트 블록(gap2).
    /// 타일은 b800 배경 + 그린(g500) 24pt 글리프가 **에셋에 구워져** 있다(코너 0) — 감싸는 도형·틴트 없이 그대로 쓴다.
    private func guideRow(icon: Image, title: String, subtitle: String) -> some View {
        HStack(spacing: .ds(.p12)) {
            icon
            // @ds(spacing): 2 — Figma 텍스트 블록 gap 2 (spacing 토큰은 4 부터 시작)
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
        // CTA 위 여백은 Spacer 몫 — 시안 812 기준 y723 이지만 기기마다 화면 높이가 달라 바닥에 붙인다.
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
