//
//  OnboardingView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import SwiftUI

/// 온보딩 위저드 진입점. 루트(JD 업로드) + 이후 스텝 스택을 NavigationStack 으로 렌더한다.
/// AppFeature 는 이 뷰만 제시하면 되고, 스텝 전환은 코디네이터(OnboardingFeature)가 담당한다.
public struct OnboardingView: View {
    @Bindable public var store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            OnboardingJobDescriptionUploadView(
                store: store.scope(state: \.jobDescriptionUpload, action: \.jobDescriptionUpload)
            )
            .onAppear { store.send(.onAppear) }
        } destination: { store in
            switch store.case {
            case let .mainProject(store):
                OnboardingMainProjectView(store: store)
            case let .portfolioUpload(store):
                OnboardingPortfolioUploadView(store: store)
            case let .preload(store):
                OnboardingPreloadView(store: store)
            }
        }
        .confirmationDialog($store.scope(state: \.relevanceChoice, action: \.relevanceChoice))
    }
}

#Preview("온보딩 플로우") {
    OnboardingView(
        store: Store(
            initialState: OnboardingFeature.State(userName: "재원", jobRole: "BACKEND", careerYears: 1)
        ) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { nil }, save: { _ in }, clear: {})
        }
    )
}
