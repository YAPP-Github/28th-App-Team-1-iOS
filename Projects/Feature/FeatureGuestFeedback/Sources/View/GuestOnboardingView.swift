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
/// 지인 피드백 온보딩 메인(Figma `[4] 온보딩 - 메인`, node 1855:8498).
/// 라이트 톤 — 타이틀 그린 하이라이트("피드백") + 부제 + 히어로 일러스트 자리(플레이스홀더) +
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
            .padding(.top, .ds(.p12))

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.Gray.g50.ignoresSafeArea())
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(requesterName)님이 당신께")
                    .dsTypography(.head4)
                    .foregroundStyle(Color.Gray.g900)
                HStack(spacing: 0) {
                    // 그린 형광펜 마커 — DS HighlightedText(Figma highlighted-text).
                    HighlightedText("피드백", typography: .head4)
                    Text("을 요청했어요")
                        .dsTypography(.head4)
                        .foregroundStyle(Color.Gray.g900)
                }
            }
            Text("이동 시간 중 딱 10분만 빌려줄 수 있나요?")
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Illustration (placeholder)

    /// 온보딩 히어로 일러스트 자리(승인된 플레이스홀더). 실 에셋이 도착하면 이 프로퍼티만 교체한다.
    private var illustration: some View {
        Rectangle() // 풀블리드 — 코너 0(각진 edge).
            .fill(Color.Gray.g100)
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(Color.Gray.g400)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Guide rows

    private var guideRows: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            // SF 심볼은 잠정 — Figma 안내 아이콘은 빈 플레이스홀더 타일이라 의미에 맞는 심볼로 대체.
            guideRow(
                icon: "eye",
                title: "AI가 못 보는 것도 있어요",
                subtitle: "눈빛, 말투 같은 순간은 당신만 알아요"
            )
            guideRow(
                icon: "bubble.left.and.bubble.right",
                title: "면접은 외우기가 아니라 대화예요",
                subtitle: "정해진 답보다 얼마나 자연스러운지를 봐주세요"
            )
        }
    }

    private func guideRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: .ds(.p12)) {
            RoundedRectangle(cornerRadius: 8) // 아이콘 타일 자리 — 실 에셋 도착 시 이미지로 교체.
                .fill(Color.Gray.g100)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .imageScale(.medium)
                        .foregroundStyle(Color.Gray.g400)
                }
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                Text(title)
                    .dsTypography(.body2)
                    .foregroundStyle(Color.Gray.g900)
                Text(subtitle)
                    .dsTypography(.body7)
                    .foregroundStyle(Color.Gray.g500)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Footer (CTA)

    private var footer: some View {
        // CTA 위 여백 — Figma 실측 마지막 가이드(y650)~버튼(y723) ≈ 73pt. 대응 spacing 토큰 부재로 리터럴.
        PrimaryButton("피드백 시작하기") {
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
