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
    /// draft 영속을 no-op 으로, date 를 고정으로 스텁한 코디네이터 스토어 (persist/clear·TTL 판정용).
    private func makeStore(_ state: OnboardingFeature.State) -> TestStoreOf<OnboardingFeature> {
        TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { nil }, save: { _ in }, clear: {})
            $0.date = .constant(Date(timeIntervalSince1970: 1_782_000_000))
        }
    }

    @Test("직군 선택 완료 시 jobRole 을 저장하고 연차 스텝을 push 한다")
    func jobSelectionContinuePushesCareerInput() async {
        let store = makeStore(OnboardingFeature.State(userName: "재원"))

        await store.send(.jobSelection(.delegate(.continueRequested(jobRole: "BACKEND")))) {
            $0.data.jobRole = "BACKEND"
            $0.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        }
    }

    @Test("직군 선택 닫기는 온보딩 종료(dismiss)로 올린다")
    func jobSelectionCloseDismissesOnboarding() async {
        let store = makeStore(OnboardingFeature.State(userName: "재원"))

        await store.send(.jobSelection(.delegate(.closeRequested)))
        await store.receive(\.delegate.dismiss)
    }

    @Test("스텝 뒤로가기는 스택을 pop 한다")
    func stepBackPopsStack() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        let store = makeStore(initialState)

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .careerInput(.delegate(.backRequested))))) {
            $0.path.removeAll()
        }
    }

    @Test("연차 완료는 career 저장 후 JD 링크 스텝을 push 한다")
    func careerContinuePushesJDLink() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        let store = makeStore(initialState)

        let id = store.state.path.ids[0]
        await store.send(
            .path(.element(id: id, action: .careerInput(.delegate(.continueRequested(careerYears: 1)))))
        ) {
            $0.data.careerYears = 1
            $0.path.append(.jdLink(.init(step: 3, totalSteps: 5)))
        }
    }

    @Test("JD 링크 스킵(nil)은 jd 필드를 비운 채 포트폴리오 스텝을 push 한다")
    func jdLinkSkipPushesPortfolioUpload() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.jdLink(.init(step: 3, totalSteps: 5)))
        let store = makeStore(initialState)

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .jdLink(.delegate(.continueRequested(nil)))))) {
            $0.path.append(.portfolioUpload(.init(step: 4, totalSteps: 5)))
        }
    }

    @Test("JD 링크 제출은 JDSubmission 을 해체 없이 jd 에 저장한다")
    func jdLinkSubmissionStoredIntact() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.jdLink(.init(step: 3, totalSteps: 5)))
        let store = makeStore(initialState)

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
        let store = makeStore(initialState)

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
        let store = makeStore(initialState)

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .analysis(.delegate(.completed(sessionId: 42))))))
        await store.receive(\.delegate.finished, 42)
        await store.finish()
    }

    @Test("분석 연관성 실패(4회 미만)는 집중 프로젝트로 되돌리고 경고를 주입한다")
    func relevanceFailurePopsBackToFocusProject() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.focusProject(.init(step: 5, totalSteps: 5)))
        initialState.path.append(.analysis(.init(data: initialState.data)))
        let store = makeStore(initialState)

        let focusId = store.state.path.ids[0]
        let analysisId = store.state.path.ids[1]
        await store.send(.path(.element(id: analysisId, action: .analysis(.delegate(.relevanceCheckFailed))))) {
            $0.relevanceFailureCount = 1
            $0.path.removeLast()   // 분석 스텝만 pop — 집중 프로젝트는 남는다.
            $0.path[id: focusId] = .focusProject(
                .init(step: 5, totalSteps: 5, inputWarning: OnboardingFeature.relevanceWarningMessage)
            )
        }
    }

    @Test("연관성 4회째 실패는 두 선택지 다이얼로그를 띄운다")
    func fourthRelevanceFailureShowsDialog() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.relevanceFailureCount = 3   // 직전까지 3회
        initialState.path.append(.focusProject(.init(step: 5, totalSteps: 5)))
        initialState.path.append(.analysis(.init(data: initialState.data)))
        let store = makeStore(initialState)

        let analysisId = store.state.path.ids[1]
        await store.send(.path(.element(id: analysisId, action: .analysis(.delegate(.relevanceCheckFailed))))) {
            $0.relevanceFailureCount = 4
            $0.path.removeLast()
            $0.relevanceChoice = OnboardingFeature.relevanceChoiceDialog()
        }
    }

    @Test("다이얼로그 '포폴 다시 올리기'는 포트폴리오 스텝으로 되돌리고 카운트를 리셋한다")
    func reuploadChoicePopsToPortfolio() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.relevanceFailureCount = 4
        initialState.path.append(.portfolioUpload(.init(step: 4, totalSteps: 5)))
        initialState.path.append(.focusProject(.init(step: 5, totalSteps: 5)))
        initialState.relevanceChoice = OnboardingFeature.relevanceChoiceDialog()
        let store = makeStore(initialState)

        await store.send(.relevanceChoice(.presented(.reuploadPortfolio))) {
            $0.relevanceFailureCount = 0
            $0.relevanceChoice = nil
            $0.path.removeLast()   // 집중 프로젝트 pop → 포트폴리오 업로드 남음
        }
    }

    @Test("다이얼로그 '집중 프로젝트 없이 진행'은 freeText 를 비우고 재분석한다")
    func proceedWithoutFocusRestartsAnalysis() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.data.jobRole = "BACKEND"
        initialState.data.freeText = "무관한 내용"
        initialState.relevanceFailureCount = 4
        initialState.path.append(.focusProject(.init(step: 5, totalSteps: 5)))
        initialState.relevanceChoice = OnboardingFeature.relevanceChoiceDialog()
        let store = makeStore(initialState)

        var expectedData = initialState.data
        expectedData.freeText = nil
        await store.send(.relevanceChoice(.presented(.proceedWithoutFocus))) {
            $0.relevanceFailureCount = 0
            $0.data.freeText = nil
            $0.relevanceChoice = nil
            $0.path.append(.analysis(.init(data: expectedData)))
        }
    }

    // MARK: - 입력 draft (PRD §4.4)

    private static let draftSavedAt = Date(timeIntervalSince1970: 1_782_000_000)

    @Test("onAppear 는 TTL 안의 draft 로 값·위저드 위치를 복원한다")
    func onAppearRestoresDraft() async {
        let draft = OnboardingDraft(
            data: OnboardingData(userName: "재원", jobRole: "BACKEND", careerYears: 2, jd: .link("https://job.com/1")),
            furthestStep: 3,
            savedAt: Self.draftSavedAt
        )
        let store = TestStore(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { draft }, save: { _ in }, clear: {})
            $0.date = .constant(Self.draftSavedAt.addingTimeInterval(60 * 60 * 24))   // 하루 뒤 — TTL 안
        }

        await store.send(.onAppear) {
            $0.didAttemptRestore = true
            $0.data = draft.data
            $0.jobSelection.preselectedJobRole = "BACKEND"
            $0.path.append(.careerInput(.init(step: 2, totalSteps: 5, selectedCareer: CareerOption(years: 2))))
            $0.path.append(.jdLink(.init(step: 3, totalSteps: 5, restoring: .link("https://job.com/1"))))
        }
    }

    @Test("onAppear 는 TTL(14일) 초과 draft 를 폐기한다")
    func onAppearDiscardsExpiredDraft() async {
        let cleared = LockIsolated(false)
        let draft = OnboardingDraft(
            data: OnboardingData(userName: "재원", jobRole: "BACKEND"),
            furthestStep: 2,
            savedAt: Self.draftSavedAt
        )
        let store = TestStore(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(
                load: { draft }, save: { _ in }, clear: { cleared.setValue(true) }
            )
            $0.date = .constant(Self.draftSavedAt.addingTimeInterval(60 * 60 * 24 * 15))   // 15일 뒤 — TTL 초과
        }

        await store.send(.onAppear) { $0.didAttemptRestore = true }
        await store.finish()
        #expect(cleared.value)
    }

    @Test("이미 스텝이 쌓여 있으면 onAppear 는 복원하지 않는다")
    func onAppearSkipsRestoreWhenPathNotEmpty() async {
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(
                load: { OnboardingDraft(data: OnboardingData(), furthestStep: 5, savedAt: Self.draftSavedAt) },
                save: { _ in }, clear: {}
            )
            $0.date = .constant(Self.draftSavedAt)
        }

        await store.send(.onAppear) { $0.didAttemptRestore = true }   // path 비어있지 않음 → 복원 안 함(플래그만 셋)
    }

    @Test("복원 후 뒤로가기로 루트까지 pop 해도 onAppear 재발동 시 재복원하지 않는다")
    func onAppearDoesNotReRestoreAfterPopToRoot() async {
        let draft = OnboardingDraft(
            data: OnboardingData(userName: "재원", jobRole: "BACKEND", careerYears: 2),
            furthestStep: 2,
            savedAt: Self.draftSavedAt
        )
        let store = TestStore(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { draft }, save: { _ in }, clear: {})
            $0.date = .constant(Self.draftSavedAt.addingTimeInterval(60 * 60 * 24))   // TTL 안
        }

        // 1) 최초 onAppear — STEP2 까지 복원
        await store.send(.onAppear) {
            $0.didAttemptRestore = true
            $0.data = draft.data
            $0.jobSelection.preselectedJobRole = "BACKEND"
            $0.path.append(.careerInput(.init(step: 2, totalSteps: 5, selectedCareer: CareerOption(years: 2))))
        }

        // 2) 뒤로가기로 루트까지 pop → path 다시 빔
        let stepId = store.state.path.ids.first!
        await store.send(.path(.element(id: stepId, action: .careerInput(.delegate(.backRequested))))) {
            $0.path.removeLast()
        }

        // 3) 루트 재등장으로 onAppear 재발동 — 이미 복원했으므로 변화 없음.
        //    (플래그 없던 버그에선 여기서 STEP2 가 다시 쌓여 화면이 앞으로 튀었다.)
        await store.send(.onAppear)
    }

    @Test("스텝 완료는 draft(데이터·재개 지점)를 저장한다")
    func stepCompletionSavesDraft() async {
        let saved = LockIsolated<OnboardingDraft?>(nil)
        let store = TestStore(initialState: OnboardingFeature.State(userName: "재원")) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { nil }, save: { saved.setValue($0) }, clear: {})
            $0.date = .constant(Self.draftSavedAt)
        }

        await store.send(.jobSelection(.delegate(.continueRequested(jobRole: "BACKEND")))) {
            $0.data.jobRole = "BACKEND"
            $0.path.append(.careerInput(.init(step: 2, totalSteps: 5)))
        }
        await store.finish()
        #expect(saved.value?.data.jobRole == "BACKEND")
        #expect(saved.value?.furthestStep == 2)
    }

    @Test("분석 완료는 draft 를 폐기한다")
    func analysisCompletionClearsDraft() async {
        let cleared = LockIsolated(false)
        var initialState = OnboardingFeature.State(userName: "재원")
        initialState.path.append(.analysis(.init(data: initialState.data)))
        let store = TestStore(initialState: initialState) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { nil }, save: { _ in }, clear: { cleared.setValue(true) })
            $0.date = .constant(Self.draftSavedAt)
        }

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .analysis(.delegate(.completed(sessionId: 1))))))
        await store.receive(\.delegate.finished, 1)
        await store.finish()
        #expect(cleared.value)
    }
}
