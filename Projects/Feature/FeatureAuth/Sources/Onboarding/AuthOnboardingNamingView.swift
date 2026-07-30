//
//  AuthOnboardingNamingView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «AuthOnboardingNaming» — 시안 수령 전 골격. NameField(DS)로 이름을 받는다.
@ViewAction(for: AuthOnboardingNamingFeature.self)
public struct AuthOnboardingNamingView: View {
    @Bindable public var store: StoreOf<AuthOnboardingNamingFeature>

    public init(store: StoreOf<AuthOnboardingNamingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressBar

            VStack(alignment: .leading, spacing: 8) {
                Text("이름을 입력해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("면접 리포트에 사용할 이름이에요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer(minLength: 0)

            NameField("이름", text: $store.name)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            ButtonLarge("계속하기", .bottom) { send(.userTappedContinue) }
                .disabled(!store.isContinueEnabled)
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
        .dismissesKeyboardOnTap()
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
}

#Preview("이름 입력") {
    AuthOnboardingNamingView(
        store: Store(initialState: AuthOnboardingNamingFeature.State()) {
            AuthOnboardingNamingFeature()
        }
    )
}
