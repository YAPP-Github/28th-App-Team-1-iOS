//
//  OnboardingDraftRestoreTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainJobInterface
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

/// 입력 draft 자동 저장·복원 (PRD §4.4). 코디네이터 본체 테스트(OnboardingCoordinatorTests)에서
/// 분리한 draft 전용 스위트 — 파일/타입 길이를 나눠 관리한다.
@MainActor
struct OnboardingDraftRestoreTests {
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
