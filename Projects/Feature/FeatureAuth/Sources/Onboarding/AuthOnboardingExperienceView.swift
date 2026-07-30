//
//  AuthOnboardingExperienceView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «AuthOnboardingExperience» — 시안 수령 전엔 면접 위저드 «STEP 2_연차»(node 1609:8561) 레이아웃 재사용.
// FeatureOnboarding OnboardingCareerInputView 의 복사본 — 가입 플로우 이관분(Feature 간 코드 공유 금지라 복사).
@ViewAction(for: AuthOnboardingExperienceFeature.self)
public struct AuthOnboardingExperienceView: View {
    @Bindable public var store: StoreOf<AuthOnboardingExperienceFeature>

    public init(store: StoreOf<AuthOnboardingExperienceFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressBar
            header
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            Spacer(minLength: 0)
            experienceSentence
            Spacer(minLength: 0)
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(
            background: .filled,
            onClose: { send(.userTappedClose) }
        )
    }

    private var progressBar: some View {
        HStack(spacing: 2) {
            ForEach(1...store.totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= store.step ? Color.HilitBlack.b800 : Color.GrayScale.g50)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("필수")
                .dsTypography(.body7)
                .foregroundStyle(Color.HilitGreen.g500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.HilitBlack.b800, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("연차를 입력해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("지금까지 근무한 모든 기간의 합\n(정규직·계약직·프리랜서 포함, 인턴)입니다.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    // MARK: - 문장형 연차 휠

    /// "내 경력은 [휠] 이다." — 앞뒤 텍스트가 휠의 선택 행(중앙)과 같은 줄에 놓인다.
    private var experienceSentence: some View {
        HStack(spacing: 12) {
            Text("내 경력은")
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
            experienceWheel
            Text("이다.")
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
        }
    }

    /// 연차 휠 — 세로 스크롤 + viewAligned 스냅으로 중앙 행이 선택값이 된다 (iOS 17 API).
    private var experienceWheel: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(store.options, id: \.self) { option in
                    Text(option.label)
                        .dsTypography(.sub4)
                        .foregroundStyle(Color.HilitBlack.b800)
                        .frame(height: WheelMetric.rowHeight)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: wheelSelection, anchor: .center)
        .contentMargins(.vertical, WheelMetric.verticalMargin, for: .scrollContent)
        .scrollIndicators(.hidden)
        .frame(width: WheelMetric.width, height: WheelMetric.height)
        .overlay { wheelFade.allowsHitTesting(false) }
    }

    /// 휠 스크롤 위치 ↔ 상태 연결 — 스냅 결과만 view 액션으로 올리고, 상태가 바뀌면 휠도 따라 스크롤된다.
    private var wheelSelection: Binding<ExperienceOption?> {
        Binding(
            get: { store.selectedExperience },
            set: { option in
                guard let option, option != store.selectedExperience else { return }
                send(.userSelectedExperience(option))
            }
        )
    }

    /// 중앙 선택 행만 또렷하게 남기는 페이드.
    private var wheelFade: some View {
        LinearGradient(
            stops: [
                .init(color: Color.BlackWhite.white, location: 0),
                .init(color: Color.BlackWhite.white.opacity(0.75), location: 0.22),
                .init(color: Color.BlackWhite.white.opacity(0), location: 0.38),
                .init(color: Color.BlackWhite.white.opacity(0), location: 0.62),
                .init(color: Color.BlackWhite.white.opacity(0.75), location: 0.78),
                .init(color: Color.BlackWhite.white, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 하단 바

    /// 하단 «이전으로 | 계속하기» 바 — 배경·구분선·등폭 배치·눌림은 `ButtonLarge(.bottom, tone: .dark)` 가 소유.
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("이전으로") { send(.userTappedBack) }
        } trailing: {
            Button("계속하기") { send(.userTappedContinue) }
        }
    }
}

// MARK: - WheelMetric

/// Figma «3안_mask» 치수 — 휠 마스크 146×206, 행 높이 44.
private enum WheelMetric {
    static let rowHeight: CGFloat = 44
    static let width: CGFloat = 146
    static let height: CGFloat = 206
    /// 첫/마지막 항목도 중앙 정렬이 가능하도록 하는 스크롤 상하 여백.
    static let verticalMargin: CGFloat = (height - rowHeight) / 2
}

// MARK: - Previews

#Preview("연차 선택 — 기본(신입)") {
    AuthOnboardingExperienceView(
        store: Store(initialState: AuthOnboardingExperienceFeature.State()) {
            AuthOnboardingExperienceFeature()
        }
    )
}

#Preview("연차 선택 — 3년차") {
    AuthOnboardingExperienceView(
        store: Store(
            initialState: AuthOnboardingExperienceFeature.State(
                selectedExperience: ExperienceOption(years: 3)
            )
        ) {
            AuthOnboardingExperienceFeature()
        }
    )
}
