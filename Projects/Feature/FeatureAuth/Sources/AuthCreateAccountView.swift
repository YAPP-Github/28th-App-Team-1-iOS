//
//  AuthCreateAccountView.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import SwiftUI

// Figma «AuthCreateAccount» — 시안 수령 전 골격. 소셜 로그인 버튼 2종만 실동작.
// PRD Part7 확정(2026-07-29): 하단은 비운다 — 간주 문구·약관 열람 링크 모두 없음(열람은 AuthTerms [보기] 전담).
@ViewAction(for: AuthCreateAccountFeature.self)
public struct AuthCreateAccountView: View {
    @Bindable public var store: StoreOf<AuthCreateAccountFeature>

    public init(store: StoreOf<AuthCreateAccountFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("hilit")
                .font(.largeTitle.bold())

            Spacer()

            VStack(spacing: 12) {
                Button {
                    send(.userTappedSignIn(.kakao))
                } label: {
                    Text("카카오로 계속하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                Button {
                    send(.userTappedSignIn(.apple))
                } label: {
                    Label("Apple로 계속하기", systemImage: "applelogo")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
            }
            .padding(.horizontal, 24)
            .disabled(store.isLoading)
            .opacity(store.isLoading ? 0.5 : 1)

            Spacer().frame(height: 40)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview("소셜 로그인") {
    AuthCreateAccountView(
        store: Store(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        }
    )
}
