//
//  FeatureOnboardingExampleApp.swift
//  FeatureOnboardingExample
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainJDInterface
import DomainPortfolioInterface
import Foundation
import FeatureOnboardingImplementation
import SwiftUI

// Feature 단독 실행 앱 — FeatureOnboarding 스킴의 실행 타겟.
// 외부 IO 는 가짜 의존성으로 주입해 네트워크 없이 전체 위저드(1→4)를 돌린다.
// 직군·연차는 가입 온보딩(FeatureAuth) 소관이라 이 위저드엔 없다 — 세션 생성은 서버 프로필 스냅샷을 쓴다.
// 환경변수 ONBOARDING_START_STEP=2...4 로 해당 스텝까지 스택을 미리 쌓고 시작할 수 있다
// (스텝 단독 확인용 — simctl: SIMCTL_CHILD_ONBOARDING_START_STEP, 스킴 environment 로도 지정 가능).
@main
struct FeatureOnboardingExampleApp: App {
    /// STEP2 를 통과한 자리를 흉내낼 때 쓰는 포폴 픽스처.
    private static let portfolioId = UUID(uuidString: "00000000-0000-0000-0000-0000000000f1")!
    private static let portfolioFileName = "포트폴리오.pdf"

    private static func initialState() -> OnboardingFeature.State {
        var state = OnboardingFeature.State(userName: "재원")
        guard
            let raw = ProcessInfo.processInfo.environment["ONBOARDING_START_STEP"],
            let startStep = Int(raw)
        else { return state }

        let total = OnboardingFeature.totalSteps
        // STEP3 이후는 STEP2 를 통과한 자리다 — 포폴 값을 같이 채운다. 안 채우면 프리로드가
        // `interviewConfig()` 에서 portfolioId 부재로 걸려 세션 생성 전에 실패 화면으로 떨어진다.
        var upload = OnboardingPortfolioUploadFeature.UploadState.idle
        if startStep >= 3 {
            state.data.portfolioId = portfolioId
            state.data.portfolioFileName = portfolioFileName
            upload = .uploaded(fileName: portfolioFileName, portfolioId: portfolioId)
        }
        if startStep >= 2 { state.path.append(.portfolioUpload(.init(step: 2, totalSteps: total, upload: upload))) }
        if startStep >= 3 { state.path.append(.mainProject(.init(step: 3, totalSteps: total))) }
        if startStep >= 4 { state.path.append(.preload(.init(data: state.data))) }
        return state
    }

    var body: some Scene {
        WindowGroup {
            OnboardingView(
                store: Store(initialState: Self.initialState()) {
                    OnboardingFeature()
                } withDependencies: {
                    // STEP 1 — 1초 뒤 유효 판정 (로딩 상태 확인용 지연).
                    $0.jdClient = JDClient(validate: { _ in
                        try await Task.sleep(for: .seconds(1))
                        return JDValidation(valid: true, reason: nil, message: nil)
                    })
                    // STEP 2 — 등록 즉시 PROCESSING, 폴링 1회 후 READY.
                    $0.portfolioClient = PortfolioClient(
                        list: { PortfolioList(portfolios: []) },
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
                    // 프리로드 — 세션 생성 즉시 PROCESSING, 폴링 1회 후 READY.
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
