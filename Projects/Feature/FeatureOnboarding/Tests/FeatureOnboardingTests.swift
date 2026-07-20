//
//  FeatureOnboardingTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainJobInterface
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

@MainActor
struct OnboardingJobSelectionFeatureTests {
    private let jobs = [
        Job(jobId: 1, jobRole: "BACKEND", label: "백엔드"),
        Job(jobId: 2, jobRole: "IOS", label: "iOS")
    ]

    @Test("진입 시 직군 목록을 로드한다")
    func loadsJobsOnAppear() async {
        let store = TestStore(initialState: OnboardingJobSelectionFeature.State()) {
            OnboardingJobSelectionFeature()
        } withDependencies: {
            $0.jobClient.jobs = { [jobs] in jobs }
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
        }
        await store.receive(\.inner.jobsLoaded) {
            $0.isLoading = false
            $0.jobs = self.jobs
        }
    }

    @Test("직군 선택 시 계속하기가 활성화된다")
    func selectingJobEnablesContinue() async {
        var initialState = OnboardingJobSelectionFeature.State()
        initialState.jobs = jobs
        let store = TestStore(initialState: initialState) {
            OnboardingJobSelectionFeature()
        }

        #expect(!store.state.isContinueEnabled)

        await store.send(.view(.userTappedJob(1))) {
            $0.selectedJobID = 1
        }

        #expect(store.state.isContinueEnabled)
    }

    @Test("계속하기는 선택 직군의 jobRole 을 delegate 로 올린다")
    func continueEmitsSelectedJobRole() async {
        var initialState = OnboardingJobSelectionFeature.State()
        initialState.jobs = jobs
        initialState.selectedJobID = 2
        let store = TestStore(initialState: initialState) {
            OnboardingJobSelectionFeature()
        }

        await store.send(.view(.userTappedContinue))
        await store.receive(\.delegate.continueRequested, "IOS")
    }

    @Test("직군 미선택 상태의 계속하기는 무시된다")
    func continueIsIgnoredWithoutSelection() async {
        let store = TestStore(initialState: OnboardingJobSelectionFeature.State()) {
            OnboardingJobSelectionFeature()
        }

        await store.send(.view(.userTappedContinue))
    }

    @Test("닫기 탭은 delegate 로 코디네이터에 위임한다")
    func closeDelegatesToCoordinator() async {
        let store = TestStore(initialState: OnboardingJobSelectionFeature.State()) {
            OnboardingJobSelectionFeature()
        }

        await store.send(.view(.userTappedClose))
        await store.receive(\.delegate.closeRequested)
    }

    @Test("로드 실패 시 로딩만 해제한다")
    func loadFailureStopsLoading() async {
        let store = TestStore(initialState: OnboardingJobSelectionFeature.State()) {
            OnboardingJobSelectionFeature()
        } withDependencies: {
            $0.jobClient.jobs = { throw NSError(domain: "test", code: -1) }
        }

        await store.send(.view(.onAppear)) {
            $0.isLoading = true
        }
        await store.receive(\.inner.jobsLoadFailed) {
            $0.isLoading = false
        }
    }
}

@MainActor
struct OnboardingCoordinatorTests {
    @Test("직군 선택 완료 시 jobRole 을 저장하고 연차 스텝을 push 한다")
    func jobSelectionContinuePushesCareerInput() async {
        let store = TestStore(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        }

        await store.send(.jobSelection(.delegate(.continueRequested(jobRole: "BACKEND")))) {
            $0.data.jobRole = "BACKEND"
            $0.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        }
    }

    @Test("직군 선택 닫기는 온보딩 종료(dismiss)로 올린다")
    func jobSelectionCloseDismissesOnboarding() async {
        let store = TestStore(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        }

        await store.send(.jobSelection(.delegate(.closeRequested)))
        await store.receive(\.delegate.dismiss)
    }

    @Test("스텝 뒤로가기는 스택을 pop 한다")
    func stepBackPopsStack() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .careerInput(.delegate(.backRequested))))) {
            $0.path.removeAll()
        }
    }

    @Test("연차 완료는 career 저장 후 JD 링크 스텝을 push 한다")
    func careerContinuePushesJDLink() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        let id = store.state.path.ids[0]
        await store.send(
            .path(.element(id: id, action: .careerInput(.delegate(.continueRequested(career: .overOneYear)))))
        ) {
            $0.data.career = .overOneYear
            $0.path.append(.jdLink(.init(step: 3, totalSteps: 5)))
        }
    }

    @Test("JD 링크 스킵(nil)은 jd 필드를 비운 채 포트폴리오 스텝을 push 한다")
    func jdLinkSkipPushesPortfolioUpload() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.jdLink(.init(step: 3, totalSteps: 5)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .jdLink(.delegate(.continueRequested(nil)))))) {
            $0.path.append(.portfolioUpload(.init(step: 4, totalSteps: 5)))
        }
    }

    @Test("JD 링크 제출은 JDSubmission 을 해체 없이 jd 에 저장한다")
    func jdLinkSubmissionStoredIntact() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.jdLink(.init(step: 3, totalSteps: 5)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        let id = store.state.path.ids[0]
        await store.send(
            .path(.element(id: id, action: .jdLink(.delegate(.continueRequested(.link("https://job.com/1"))))))
        ) {
            $0.data.jd = .link("https://job.com/1")
            $0.path.append(.portfolioUpload(.init(step: 4, totalSteps: 5)))
        }
    }

    @Test("집중 프로젝트 완료는 누적 데이터를 들고 분석 스텝을 push 한다")
    func focusProjectContinuePushesAnalysisWithData() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.data.jobRole = "BACKEND"
        initialState.path.append(.focusProject(.init(step: 5, totalSteps: 5)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        var expectedData = initialState.data
        expectedData.freeText = "결제 시스템 리팩토링"

        let id = store.state.path.ids[0]
        await store.send(
            .path(.element(id: id, action: .focusProject(.delegate(.continueRequested(freeText: "결제 시스템 리팩토링")))))
        ) {
            $0.data.freeText = "결제 시스템 리팩토링"
            $0.path.append(.analysis(.init(data: expectedData)))
        }
    }

    @Test("분석 완료는 세션 id 를 들고 온보딩 완료(finished)로 올린다")
    func analysisCompletedFinishesOnboarding() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.analysis(.init(data: initialState.data)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .analysis(.delegate(.completed(sessionId: 42))))))
        await store.receive(\.delegate.finished, 42)
    }

    @Test("분석 연관성 실패는 집중 프로젝트로 되돌리고 실패 횟수를 센다")
    func relevanceFailurePopsBackToFocusProject() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.focusProject(.init(step: 5, totalSteps: 5)))
        initialState.path.append(.analysis(.init(data: initialState.data)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        }

        let analysisId = store.state.path.ids[1]
        await store.send(.path(.element(id: analysisId, action: .analysis(.delegate(.relevanceCheckFailed))))) {
            $0.relevanceFailureCount = 1
            $0.path.removeLast()   // 분석 스텝만 pop — 집중 프로젝트는 남는다.
        }
    }
}
