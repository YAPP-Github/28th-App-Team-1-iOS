//
//  OnboardingPlaceholderStepView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// 온보딩 STEP 2+ 자리표시 뷰. 직군 선택과 같은 골격(내비바·프로그레스 바·하단 CTA)만 두고
// 본문은 비워 뒀다 — 실제 스텝 Figma 가 오면 OnboardingJobSelectionView 처럼 채운다.
@ViewAction(for: OnboardingPlaceholderStepFeature.self)
public struct OnboardingPlaceholderStepView: View {
    @Bindable public var store: StoreOf<OnboardingPlaceholderStepFeature>

    public init(store: StoreOf<OnboardingPlaceholderStepFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            progressBar
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
        .navigationBarBackButtonHidden(true)
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedBack)
            } label: {
                Image.Ic.close
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.HilitBlack.b800)
                    .rotationEffect(.degrees(45)) // TODO: 뒤로(chevron) 아이콘 에셋 추가 시 교체
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Button {
                send(.userTappedClose)
            } label: {
                Image.Ic.close
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.HilitBlack.b800)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
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

    private var continueButton: some View {
        Button {
            send(.userTappedContinue)
        } label: {
            Text("계속하기")
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.HilitBlack.b800.ignoresSafeArea(edges: .bottom))
    }
}

#Preview("스텝 템플릿") {
    OnboardingPlaceholderStepView(
        store: Store(initialState: OnboardingPlaceholderStepFeature.State(step: 2, totalSteps: 5)) {
            OnboardingPlaceholderStepFeature()
        }
    )
}
