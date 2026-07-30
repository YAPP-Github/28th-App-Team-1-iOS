//
//  AuthOnboardingRegisterView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «AuthOnboardingRegister» — 시안 수령 전 골격. 완료 문구 + 시작 CTA 만.
// 종결 화면이라 프로그레스·뒤로가기 없음(내비바도 없음 — 이탈 경로를 두지 않는다).
@ViewAction(for: AuthOnboardingRegisterFeature.self)
public struct AuthOnboardingRegisterView: View {
    @Bindable public var store: StoreOf<AuthOnboardingRegisterFeature>

    public init(store: StoreOf<AuthOnboardingRegisterFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("등록이 완료됐어요!")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("\(store.userName)님, 이제 면접 연습을 시작해 보세요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
            .multilineTextAlignment(.center)

            Spacer()

            ButtonLarge("시작하기", .bottom) { send(.userTappedStart) }
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

#Preview("등록 완료") {
    AuthOnboardingRegisterView(
        store: Store(initialState: AuthOnboardingRegisterFeature.State(userName: "재원")) {
            AuthOnboardingRegisterFeature()
        }
    )
}
