//
//  FeatureOnboardingExampleApp.swift
//  FeatureOnboardingExample
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainJobInterface
import FeatureOnboardingImplementation
import SwiftUI

// Feature 단독 실행 앱 — FeatureOnboarding 스킴의 실행 타겟.
// 외부 IO 는 가짜 의존성으로 주입해 네트워크 없이 돌린다 (Figma STEP 1 선택지 6종 스텁).
@main
struct FeatureOnboardingExampleApp: App {
    var body: some Scene {
        WindowGroup {
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
    }
}
