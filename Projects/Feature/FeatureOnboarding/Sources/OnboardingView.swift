//
//  OnboardingView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainJobInterface
import SwiftUI

/// 온보딩 위저드 진입점. 루트(직군 선택) + 이후 스텝 스택을 NavigationStack 으로 렌더한다.
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
            OnboardingJobSelectionView(
                store: store.scope(state: \.jobSelection, action: \.jobSelection)
            )
        } destination: { store in
            switch store.case {
            case let .placeholder(store):
                OnboardingPlaceholderStepView(store: store)
            }
        }
    }
}

#Preview("온보딩 플로우") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        } withDependencies: {
            $0.jobClient = JobClient(jobs: {
                [
                    Job(jobId: 1, jobRole: "BACKEND", label: "백엔드"),
                    Job(jobId: 2, jobRole: "ANDROID", label: "Android"),
                    Job(jobId: 3, jobRole: "IOS", label: "iOS"),
                    Job(jobId: 4, jobRole: "FRONTEND", label: "프론트엔드"),
                    Job(jobId: 5, jobRole: "DATA_ENGINEER", label: "데이터 엔지니어"),
                    Job(jobId: 6, jobRole: "INFRA_SRE", label: "인프라 ⋅ SRE")
                ]
            })
        }
    )
}
