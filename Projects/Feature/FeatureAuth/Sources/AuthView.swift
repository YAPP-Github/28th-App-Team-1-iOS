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

            // 로그인 진행 중에는 모든 provider 버튼을 함께 비활성화한다 —
            // 레이아웃 유지 + 다른 provider로의 동시 로그인 시도 차단.
            // 애플 로그인 버튼이 추가되면 이 VStack에 넣기만 하면 같은 규칙을 상속받는다.
            VStack(spacing: 12) {
                Button {
                    store.send(.userTappedSignIn(.kakao))
                } label: {
                    Text("카카오로 로그인")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .disabled(store.isLoading)
            .opacity(store.isLoading ? 0.5 : 1)

            Spacer().frame(height: 40)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
