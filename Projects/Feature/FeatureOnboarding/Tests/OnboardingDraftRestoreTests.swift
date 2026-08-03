//
//  OnboardingDraftRestoreTests.swift
//  FeatureOnboardingTests
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import FeatureOnboardingImplementation

/// 입력 draft 자동 저장·복원 (PRD §4.4). 코디네이터 본체 테스트(OnboardingCoordinatorTests)에서
/// 분리한 draft 전용 스위트 — 파일/타입 길이를 나눠 관리한다.
@MainActor
struct OnboardingDraftRestoreTests {
    private static let draftSavedAt = Date(timeIntervalSince1970: 1_782_000_000)

    /// 위저드 총 스텝 수 — 프로덕션 상수를 그대로 써서 스텝 수가 바뀌면 테스트도 따라간다.
    private let total = OnboardingFeature.totalSteps

    /// 직군·연차는 가입 온보딩(FeatureAuth) 소관이라 위저드엔 주입값으로 들어온다.
    private func initialState() -> OnboardingFeature.State {
        OnboardingFeature.State(userName: "재원", jobRole: "BACKEND", careerYears: 2)
    }

    @Test("onAppear 는 TTL 안의 draft 로 값·위저드 위치를 복원한다")
    func onAppearRestoresDraft() async {
        let portfolioId = UUID(uuidString: "00000000-0000-0000-0000-0000000000f1")!
        let draft = OnboardingDraft(
            data: OnboardingData(
                userName: "재원",
                jobRole: "BACKEND",
                careerYears: 2,
                jd: .link("https://job.com/1"),
                portfolioId: portfolioId,
                portfolioFileName: "포폴.pdf"
            ),
            furthestStep: 2,
            savedAt: Self.draftSavedAt
        )
        let store = TestStore(initialState: initialState()) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { draft }, save: { _ in }, clear: {})
            $0.date = .constant(Self.draftSavedAt.addingTimeInterval(60 * 60 * 24))   // 하루 뒤 — TTL 안
        }

        await store.send(.onAppear) {
            $0.didAttemptRestore = true
            $0.data = draft.data
            $0.jobDescriptionUpload = .init(step: 1, totalSteps: self.total, restoring: .link("https://job.com/1"))
            $0.path.append(.portfolioUpload(.init(
                step: 2, totalSteps: self.total,
                upload: .uploaded(fileName: "포폴.pdf", portfolioId: portfolioId)
            )))
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
        let store = TestStore(initialState: initialState()) {
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
        var state = initialState()
        state.path.append(.portfolioUpload(.init(step: 2, totalSteps: total)))
        let store = TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(
                load: { OnboardingDraft(data: OnboardingData(), furthestStep: 3, savedAt: Self.draftSavedAt) },
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
        let store = TestStore(initialState: initialState()) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { draft }, save: { _ in }, clear: {})
            $0.date = .constant(Self.draftSavedAt.addingTimeInterval(60 * 60 * 24))   // TTL 안
        }

        // 1) 최초 onAppear — STEP2 까지 복원
        await store.send(.onAppear) {
            $0.didAttemptRestore = true
            $0.data = draft.data
            $0.jobDescriptionUpload = .init(step: 1, totalSteps: self.total, restoring: nil)
            $0.path.append(.portfolioUpload(.init(step: 2, totalSteps: self.total)))
        }

        // 2) 뒤로가기로 루트까지 pop → path 다시 빔
        let stepId = store.state.path.ids.first!
        await store.send(.path(.element(id: stepId, action: .portfolioUpload(.delegate(.backRequested))))) {
            $0.path.removeLast()
        }

        // 3) 루트 재등장으로 onAppear 재발동 — 이미 복원했으므로 변화 없음.
        //    (플래그 없던 버그에선 여기서 STEP2 가 다시 쌓여 화면이 앞으로 튀었다.)
        await store.send(.onAppear)
    }

    @Test("스텝 완료는 draft(데이터·재개 지점)를 저장한다")
    func stepCompletionSavesDraft() async {
        let saved = LockIsolated<OnboardingDraft?>(nil)
        let store = TestStore(initialState: initialState()) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(load: { nil }, save: { saved.setValue($0) }, clear: {})
            $0.date = .constant(Self.draftSavedAt)
        }

        await store.send(.jobDescriptionUpload(.delegate(.continueRequested(.link("https://job.com/1"))))) {
            $0.data.jd = .link("https://job.com/1")
            $0.path.append(.portfolioUpload(.init(step: 2, totalSteps: self.total)))
        }
        await store.finish()
        #expect(saved.value?.data.jd == .link("https://job.com/1"))
        #expect(saved.value?.furthestStep == 2)
    }

    /// 세션 생성은 면접의 시작일 뿐 — 폐기는 인터뷰 세션 완료 시점(AppFeature)이다.
    @Test("프리로드 완료는 draft 를 남긴다")
    func preloadCompletionKeepsDraft() async {
        let cleared = LockIsolated(false)
        var state = initialState()
        state.path.append(.preload(.init(data: state.data)))
        let store = TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingDraftStore = OnboardingDraftStore(
                load: { nil }, save: { _ in }, clear: { cleared.setValue(true) }
            )
            $0.date = .constant(Self.draftSavedAt)
        }

        let id = store.state.path.ids[0]
        await store.send(.path(.element(id: id, action: .preload(.delegate(.completed(sessionId: 1))))))
        await store.receive(\.delegate.finished, 1)
        await store.finish()
        #expect(!cleared.value)
    }
}
