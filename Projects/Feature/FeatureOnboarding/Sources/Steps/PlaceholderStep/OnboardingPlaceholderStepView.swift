//
//  OnboardingPlaceholderStepView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// 온보딩 STEP 2+ 자리표시 뷰. 직군 선택과 같은 골격(네비바·프로그레스 바·하단 CTA)만 두고
// 본문은 비워 뒀다 — 실제 스텝 Figma 가 오면 OnboardingJobSelectionView 처럼 채운다.
@ViewAction(for: OnboardingPlaceholderStepFeature.self)
public struct OnboardingPlaceholderStepView: View {
    @Bindable public var store: StoreOf<OnboardingPlaceholderStepFeature>

    public init(store: StoreOf<OnboardingPlaceholderStepFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DashIndicator(count: store.totalSteps, current: store.step)
            Spacer()
            Text(store.title)
                .dsTypography(.head3)
                .foregroundStyle(Color.GrayScale.g800)
            Text("STEP \(store.step) — 디자인 연결 예정")
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g500)
                .padding(.top, 8)
            Spacer()
            continueButton
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        // 최종 시안은 뒤로 버튼 없음(X 통일) — 뒤로는 스와이프백·하단 바 몫.
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
    }

    private var continueButton: some View {
        ButtonLarge("계속하기", .bottom) { send(.userTappedContinue) }
    }
}

#Preview("스텝 템플릿") {
    OnboardingPlaceholderStepView(
        store: Store(initialState: OnboardingPlaceholderStepFeature.State(step: 2, totalSteps: 5)) {
            OnboardingPlaceholderStepFeature()
        }
    )
}
