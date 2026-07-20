//
//  FeatureOnboardingExampleApp.swift
//  FeatureOnboardingExample
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainJDInterface
import DomainJobInterface
import DomainPortfolioInterface
import Foundation
import FeatureOnboardingImplementation
import SwiftUI

// Feature 단독 실행 앱 — FeatureOnboarding 스킴의 실행 타겟.
// 외부 IO 는 가짜 의존성으로 주입해 네트워크 없이 전체 위저드(1→6)를 돌린다.
// 환경변수 ONBOARDING_START_STEP=2...6 으로 해당 스텝까지 스택을 미리 쌓고 시작할 수 있다
// (스텝 단독 확인용 — simctl: SIMCTL_CHILD_ONBOARDING_START_STEP, 스킴 environment 로도 지정 가능).
@main
struct FeatureOnboardingExampleApp: App {
    private static func initialState() -> OnboardingFeature.State {
        var state = OnboardingFeature.State(userName: "재원")
        guard
            let raw = ProcessInfo.processInfo.environment["ONBOARDING_START_STEP"],
            let startStep = Int(raw)
        else { return state }

        let total = OnboardingFeature.totalSteps
        state.data.jobRole = "BACKEND"
        if startStep >= 2 { state.path.append(.careerInput(.init(step: 2, totalSteps: total))) }
        if startStep >= 3 { state.path.append(.jdLink(.init(step: 3, totalSteps: total))) }
        if startStep >= 4 { state.path.append(.portfolioUpload(.init(step: 4, totalSteps: total))) }
        if startStep >= 5 { state.path.append(.focusProject(.init(step: 5, totalSteps: total))) }
        if startStep >= 6 { state.path.append(.analysis(.init(data: state.data))) }
        return state
    }

    var body: some Scene {
        WindowGroup {
            OnboardingView(
                store: Store(initialState: Self.initialState()) {
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
                    // STEP 3 — 1초 뒤 유효 판정 (로딩 상태 확인용 지연).
                    $0.jdClient = JDClient(validate: { _ in
                        try await Task.sleep(for: .seconds(1))
                        return JDValidation(valid: true, reason: nil, message: nil)
                    })
                    // STEP 4 — 등록 즉시 PROCESSING, 폴링 1회 후 READY.
                    $0.portfolioClient = PortfolioClient(
                        list: { [] },
                        register: { upload in
                            try await Task.sleep(for: .seconds(1))
                            return PortfolioProcessing(
                                portfolioId: UUID(),
                                status: .processing,
                                message: upload.fileName
                            )
                        },
                        status: { id in
                            PortfolioProcessing(portfolioId: id, status: .ready, message: nil)
                        },
                        delete: { id in
                            PortfolioDeletion(portfolioId: id, deletedAt: nil)
                        }
                    )
                    // STEP 6 분석 — 세션 생성 즉시 PROCESSING, 폴링 1회 후 READY.
                    $0.interviewClient.createSession = { _ in
                        try await Task.sleep(for: .seconds(1))
                        return InterviewSessionCreated(sessionId: 1, status: "PROCESSING", statusUrl: nil)
                    }
                    $0.interviewClient.sessionStatus = { _ in
                        InterviewSessionStatus(status: .ready, startedAt: nil, summaryQuestion: nil)
                    }
                    // draft — Example 은 항상 새로 시작(복원 끔), 저장/삭제는 무시.
                    $0.onboardingDraftStore = OnboardingDraftStore(load: { nil }, save: { _ in }, clear: {})
                }
            )
        }
    }
}
