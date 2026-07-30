//
//  AuthView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SwiftUI

/// 가입·로그인 플로우 진입점. 루트(A0 소셜 로그인) + 가입 경로 스택을 NavigationStack 으로 렌더한다.
/// AppFeature 는 이 뷰만 제시하면 되고, 화면 전환은 코디네이터(AuthFeature)가 담당한다.
/// AuthSuspension(A4)은 이 스택 밖 — 홈 게이트 응답으로 AppFeature 가 별도 제시한다.
public struct AuthView: View {
    @Bindable public var store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            AuthCreateAccountView(
                store: store.scope(state: \.createAccount, action: \.createAccount)
            )
        } destination: { store in
            switch store.case {
            case let .terms(store):
                AuthTermsView(store: store)
            case let .naming(store):
                AuthOnboardingNamingView(store: store)
            case let .job(store):
                AuthOnboardingJobView(store: store)
            case let .experience(store):
                AuthOnboardingExperienceView(store: store)
            case let .register(store):
                AuthOnboardingRegisterView(store: store)
            }
        }
    }
}

#Preview("가입 플로우") {
    AuthView(
        store: Store(initialState: AuthFeature.State()) {
            AuthFeature()
        }
    )
}
