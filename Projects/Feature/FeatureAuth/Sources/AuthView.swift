//
//  AuthView.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import SwiftUI

public struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
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
                    store.send(.userTappedSignIn(.kakao))
                } label: {
                    Text("카카오로 로그인")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                Button {
                    store.send(.userTappedSignIn(.apple))
                } label: {
                    Label("Apple로 로그인", systemImage: "applelogo")
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
