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
/// 라이트 톤 — 타이틀 그린 하이라이트("피드백") + 부제 + 히어로 일러스트(g100 판 위 214 정사각) +
/// 안내 2행 + 하단 블랙 CTA. 닉네임 입력은 다음 스텝(GuestNicknameView).
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestOnboardingView: View {
    let store: StoreOf<GuestFeedbackFeature>

    private var requesterName: String { store.entry?.requesterName ?? "지원자" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: .ds(.p24)) {
                titleBlock
                    .padding(.horizontal, .ds(.p20))
                illustration   // 풀블리드 — 양쪽 여백 없이 화면 폭 전체 (Figma node 1855:8499, x0 w375)
                guideRows
                    .padding(.horizontal, .ds(.p20))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // @ds(spacing): 34 — 타이틀 시작(Figma title-box y77 − 상태바 43). 스케일에 34 가 없다.
            // 좌상단 닫기 X(위 10 + 글리프 24)가 끝나는 높이와 같아 글자와 겹치지 않는다.
            .padding(.top, 34)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.GrayScale.g50.ignoresSafeArea())
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(requesterName)님이 당신께")
                    .dsTypography(.head4)
                    .foregroundStyle(Color.GrayScale.g900)
                // 그린 형광펜 마커 — DS HighlightedText(Figma highlighted-text).
                HighlightedText("피드백을 요청했어요", typography: .head4).hilight("피드백")
            }
            Text("이동 시간 중 딱 10분만 빌려줄 수 있나요?")
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Illustration

    /// 온보딩 히어로 — Figma «Frame 2147230590»(3683:9109): 판 위쪽에서 60 내려온 자리에 214 정사각
    /// 일러스트(`feedback/214px`)를 가운데로 둔다. 판은 풀블리드고 **위 모서리만** 4pt 둥글다.
    /// 판 높이는 시안이 406 이지만 여기선 남는 세로를 다 먹는다 — 시안 auto-layout 이 items-start 라
    /// 화면이 길어지면 아래쪽 여백만 늘어나는 게 맞다(일러스트는 위에서 60 자리를 지킨다).
    private var illustration: some View {
        // 에셋 원본이 214 정사각이라 크기를 지정하지 않는다 (image.md 크기 규칙).
        Image.Img.feedback
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // @ds(color): #F3F4F6 → GrayScale.g100 — 일러스트 판. 팔레트엔 g50(#F6F7F9)·g100(#EBECF1) 뿐이고,
            // 페이지 배경(g50)보다 한 단계 어두워야 판이 보인다는 관계가 시안의 요점이라 g100 을 쓴다.
            .background(Color.GrayScale.g100)
            // @ds(radius): 4 — 판 위 모서리(아래는 각짐). DSRadius 토큰 없음
            .clipShape(.rect(topLeadingRadius: 4, topTrailingRadius: 4))
    }

    // MARK: - Guide rows

    private var guideRows: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            guideRow(
                icon: Image.Img.person,          // Figma icon1 = person/40px (435:656)
                title: "AI가 못 보는 것도 있어요",
                subtitle: "눈빛, 말투 같은 순간은 당신만 알아요"
            )
            guideRow(
                icon: Image.Img.talk,            // Figma icon2 = talk/40px (435:652)
                title: "면접은 외우기가 아니라 대화예요",
                subtitle: "정해진 답보다 얼마나 자연스러운지를 봐주세요"
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
        // CTA 위 여백 — Figma 실측 마지막 가이드(y650)~버튼(y723) ≈ 73pt. 대응 spacing 토큰 부재로 리터럴.
        ButtonLarge("피드백 시작하기", .bottom) {
            send(.startTapped)
        }
        .padding(.top, 72)
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
