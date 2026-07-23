//
//  GuestFeedbackEvaluationTests.swift
//  FeatureGuestFeedbackTests
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainFeedbackInterface
import DomainFeedbackTesting
import Foundation
import Testing
@testable import FeatureGuestFeedbackImplementation

@MainActor
struct GuestFeedbackEvaluationTests {
    private let gaze = AttitudeAxis(code: "GAZE", displayName: "시선")

    /// 평가 중 상태에서 시작하는 스토어 — 진입 플로우는 EntryFlowTests 가 검증하므로 생략한다.
    /// activeAxis 는 videoReady 진입과 동일하게 첫 축(GAZE)으로 세팅한다.
    private func makeEvaluatingStore(
        localStore: GuestFeedbackLocalStore = .inMemory()
    ) -> TestStoreOf<GuestFeedbackFeature> {
        var state = GuestFeedbackFeature.State(token: "t1")
        state.entry = .fixture()
        state.phase = .evaluating
        state.startedEvaluation = true
        state.activeAxis = AttitudeAxis.allFive.first
        return TestStore(initialState: state) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = .mock()
            $0.guestFeedbackLocalStore = localStore
            $0.continuousClock = ImmediateClock()
        }
    }

    @Test("칩 선택은 활성 축의 레벨을 저장하고 임시저장된다")
    func levelSelectedSetsRatingAndPersists() async {
        let localStore = GuestFeedbackLocalStore.inMemory()
        let store = makeEvaluatingStore(localStore: localStore)

        await store.send(.view(.levelSelected(2))) {
            $0.ratings["GAZE"] = RatingDraft(level: 2, comment: "")
            $0.savingAxisCode = "GAZE"
        }
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
        await store.finish()

        #expect(localStore.loadDraft("t1")?.ratings["GAZE"] == RatingDraft(level: 2, comment: ""))
    }

    @Test("칩 선택은 저장 중 상태를 걸고 draft 저장 완료가 해제한다")
    func levelSelectedDrivesSavingIndicator() async {
        let store = makeEvaluatingStore()

        await store.send(.view(.levelSelected(2))) {
            $0.ratings["GAZE"] = RatingDraft(level: 2, comment: "")
            $0.savingAxisCode = "GAZE"
        }
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
    }

    @Test("범위를 벗어난 레벨은 무시된다")
    func levelSelectedRejectsOutOfRange() async {
        let store = makeEvaluatingStore()

        await store.send(.view(.levelSelected(0)))   // 상태 변화 없음
        await store.send(.view(.levelSelected(5)))   // 상태 변화 없음
    }

    @Test("세그먼트를 바꾸면 활성 축이 바뀌고 코멘트 편집이 닫힌다")
    func axisSelectedSwitchesAxisAndClosesComment() async {
        let store = makeEvaluatingStore()
        let voice = AttitudeAxis(code: "VOICE", displayName: "목소리")

        await store.send(.view(.commentEditTapped)) {
            $0.commentEditing = true
        }
        await store.send(.view(.axisSelected(voice))) {
            $0.activeAxis = voice
            $0.commentEditing = false
            $0.isImmersiveWatching = false
        }
    }

    @Test("몰입 시청에서 축을 탭하면 평가 카드 모드로 내려오고, 확대 버튼이 몰입으로 되돌린다")
    func immersiveTogglesByAxisTapAndExpand() async {
        let store = makeEvaluatingStore()   // 최초 진입 기본값 = 몰입

        #expect(store.state.isImmersiveWatching)
        await store.send(.view(.axisSelected(gaze))) {
            $0.isImmersiveWatching = false
        }
        await store.send(.view(.expandVideoTapped)) {
            $0.isImmersiveWatching = true
        }
    }

    @Test("코멘트 편집 후 저장하면 활성 축 코멘트가 반영되고 임시저장된다")
    func commentDoneSavesComment() async {
        let localStore = GuestFeedbackLocalStore.inMemory()
        let store = makeEvaluatingStore(localStore: localStore)

        await store.send(.view(.levelSelected(1))) {
            $0.ratings["GAZE"] = RatingDraft(level: 1, comment: "")
            $0.savingAxisCode = "GAZE"
        }
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
        await store.finish()   // levelSelected 의 debounce 저장 드레인 → 이후 saveDraftNow 와 쓰기 순서 확정

        await store.send(.view(.commentEditTapped)) {
            $0.commentEditing = true
        }
        await store.send(.view(.binding(.set(\.commentDraft, "좋았어요")))) {
            $0.commentDraft = "좋았어요"
        }
        await store.send(.view(.commentDoneTapped)) {
            $0.commentEditing = false
            $0.ratings["GAZE"] = RatingDraft(level: 1, comment: "좋았어요")
        }
        await store.finish()

        #expect(localStore.loadDraft("t1")?.ratings["GAZE"] == RatingDraft(level: 1, comment: "좋았어요"))
    }

    @Test("코멘트를 저장 없이 닫으면 편집분은 확정값에 반영되지 않는다")
    func commentDismissDiscardsUnsavedEdit() async {
        let store = makeEvaluatingStore()

        await store.send(.view(.levelSelected(1))) {
            $0.ratings["GAZE"] = RatingDraft(level: 1, comment: "")
            $0.savingAxisCode = "GAZE"
        }
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
        await store.finish()

        await store.send(.view(.commentEditTapped)) {
            $0.commentEditing = true
        }
        await store.send(.view(.binding(.set(\.commentDraft, "안 저장할래요")))) {
            $0.commentDraft = "안 저장할래요"
        }
        await store.send(.view(.commentDismissed)) {
            $0.commentEditing = false
        }

        // 저장하지 않았으므로 확정 코멘트는 그대로 비어 있다.
        #expect(store.state.ratings["GAZE"] == RatingDraft(level: 1, comment: ""))
    }

    @Test("항목 코멘트는 허용 문자만 남기고 100자에서 자른다")
    func commentDraftIsSanitized() async {
        let store = makeEvaluatingStore()
        let long = String(repeating: "가", count: 120) + "😀★"

        await store.send(.view(.commentEditTapped)) {
            $0.commentEditing = true
        }
        await store.send(.view(.binding(.set(\.commentDraft, long)))) {
            $0.commentDraft = String(repeating: "가", count: 100)
        }
    }

    @Test("전반 피드백은 300자 제한이고 변경 시 임시저장된다")
    func overallFeedbackIsSanitizedAndPersisted() async {
        let localStore = GuestFeedbackLocalStore.inMemory()
        let store = makeEvaluatingStore(localStore: localStore)
        let long = String(repeating: "a", count: 310)

        await store.send(.view(.binding(.set(\.overallFeedback, long)))) {
            $0.overallFeedback = String(repeating: "a", count: 300)
        }
        await store.receive(\.inner.draftSaved)
        await store.finish()

        #expect(localStore.loadDraft("t1")?.overallFeedback == String(repeating: "a", count: 300))
    }

    @Test("시청 전용(FULL)에서는 레벨을 선택해도 저장되지 않는다")
    func viewingOnlyBlocksEvaluation() async {
        var state = GuestFeedbackFeature.State(token: "t1")
        state.entry = .fixture(gate: .full, submissionOpen: false)
        state.phase = .evaluating
        state.activeAxis = gaze
        let store = TestStore(initialState: state) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = .mock()
            $0.guestFeedbackLocalStore = .inMemory()
            $0.continuousClock = ImmediateClock()
        }

        await store.send(.view(.levelSelected(2)))   // canEvaluate false → 상태 변화 없음
    }

    @Test("모든 축을 채우면 리뷰 탭이 요약으로 넘어가고, 미완이면 무시된다")
    func reviewTappedGoesToSummaryOnlyWhenAllAxesRated() async {
        let store = makeEvaluatingStore()

        // 한 축만 채운 상태 — isSubmitEnabled false → reviewTapped 는 no-op(phase 유지)
        await store.send(.view(.levelSelected(1))) {
            $0.ratings["GAZE"] = RatingDraft(level: 1, comment: "")
            $0.savingAxisCode = "GAZE"
        }
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
        #expect(store.state.isSubmitEnabled == false)
        await store.send(.view(.reviewTapped))   // 미완이라 phase 는 .evaluating 그대로

        // 나머지 축까지 모두 채운다
        for axis in AttitudeAxis.allFive.dropFirst() {
            await store.send(.view(.axisSelected(axis))) {
                $0.activeAxis = axis
                $0.isImmersiveWatching = false
            }
            await store.send(.view(.levelSelected(1))) {
                $0.ratings[axis.code] = RatingDraft(level: 1, comment: "")
                $0.savingAxisCode = axis.code
            }
            await store.receive(\.inner.draftSaved) {
                $0.savingAxisCode = nil
            }
        }

        // 모든 축 완료 → reviewTapped 가 summary 로 전이한다
        #expect(store.state.isSubmitEnabled)
        await store.send(.view(.reviewTapped)) {
            $0.phase = .summary
        }
        await store.finish()
    }

    // MARK: - 요약 → 평가 되돌아가기

    /// 요약 상태 스토어 — 전 축 완료 후 reviewTapped 를 거친 상태를 직접 구성한다.
    private func makeSummaryStore(isImmersiveWatching: Bool) -> TestStoreOf<GuestFeedbackFeature> {
        var state = GuestFeedbackFeature.State(token: "t1")
        state.entry = .fixture()
        state.phase = .summary
        state.startedEvaluation = true
        state.isImmersiveWatching = isImmersiveWatching
        state.activeAxis = AttitudeAxis.allFive.first
        for axis in AttitudeAxis.allFive {
            state.ratings[axis.code] = RatingDraft(level: 1, comment: "")
        }
        return TestStore(initialState: state) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = .mock()
            $0.guestFeedbackLocalStore = .inMemory()
            $0.continuousClock = ImmediateClock()
        }
    }

    @Test("요약 카드 탭은 해당 축의 평가 카드 모드로 되돌린다")
    func summaryCardTappedReturnsToAxisEditing() async {
        let store = makeSummaryStore(isImmersiveWatching: true)   // 다시보기→재요약 경로도 카드로 열려야 한다
        let voice = AttitudeAxis(code: "VOICE", displayName: "목소리")

        await store.send(.view(.summaryCardTapped(voice))) {
            $0.activeAxis = voice
            $0.isImmersiveWatching = false
            $0.phase = .evaluating
        }
    }

    @Test("요약 영상 다시보기는 몰입 시청으로 평가에 되돌아간다")
    func rewatchTappedReturnsToImmersiveWatching() async {
        let store = makeSummaryStore(isImmersiveWatching: false)

        await store.send(.view(.rewatchTapped)) {
            $0.isImmersiveWatching = true
            $0.phase = .evaluating
        }
    }
}
