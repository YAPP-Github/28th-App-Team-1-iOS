//
//  GuestFeedbackEvaluationTests.swift
//  FeatureGuestFeedbackTests
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import DomainGuestFeedbackTesting
import Foundation
import Testing
@testable import FeatureGuestFeedbackImplementation

@MainActor
struct GuestFeedbackEvaluationTests {
    private let gaze = AttitudeAxis(code: "GAZE", displayName: "시선")

    /// 평가 중 상태에서 시작하는 스토어 — 진입 플로우는 EntryFlowTests 가 검증하므로 생략한다.
    /// activeAxis 는 시작 연출을 마치고 들어온 것과 동일하게 첫 축(GAZE)으로 세팅한다.
    private func makeEvaluatingStore(
        localStore: GuestFeedbackLocalStore = .inMemory(),
        clock: any Clock<Duration> = ImmediateClock()
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
            $0.continuousClock = clock
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
        await store.receive(\.inner.draftSaved)
        await store.finish()

        #expect(localStore.loadDraft("t1")?.ratings["GAZE"] == RatingDraft(level: 1, comment: "좋았어요"))
    }

    @Test("debounce 저장이 대기 중이어도 코멘트 확정이 최종 영속값으로 남는다")
    func commentDoneDuringPendingDebounceKeepsLatestDraft() async {
        let clock = TestClock()
        let localStore = GuestFeedbackLocalStore.inMemory()
        let store = makeEvaluatingStore(localStore: localStore, clock: clock)
        store.exhaustivity = .off   // 검증 대상은 쓰기 순서의 최종 영속값 하나뿐

        await store.send(.view(.levelSelected(2)))   // debounce 저장 500ms 대기 시작
        await store.send(.view(.commentEditTapped))
        await store.send(.view(.binding(.set(\.commentDraft, "좋았어요"))))
        await store.send(.view(.commentDoneTapped))          // 즉시 저장 — 대기 중 debounce 를 취소해야 한다
        await clock.advance(by: .milliseconds(500))          // stale 스냅샷이 살아 있다면 여기서 덮어쓴다
        await store.finish()

        #expect(localStore.loadDraft("t1")?.ratings["GAZE"] == RatingDraft(level: 2, comment: "좋았어요"))
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

        // 마지막 하나만 남기고 나머지 축을 채운다
        for axis in AttitudeAxis.allFive.dropFirst().dropLast() {
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

        // 마지막 축 — 완료 전이 순간이라 완료 토스트가 함께 뜬다
        let last = AttitudeAxis.allFive.last!
        await store.send(.view(.axisSelected(last))) {
            $0.activeAxis = last
            $0.isImmersiveWatching = false
        }
        await store.send(.view(.levelSelected(1))) {
            $0.ratings[last.code] = RatingDraft(level: 1, comment: "")
            $0.savingAxisCode = last.code
            $0.isCompletionToastVisible = true
        }
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
        await store.receive(\.inner.completionToastExpired) {
            $0.isCompletionToastVisible = false
        }

        // 모든 축 완료 → reviewTapped 가 summary 로 전이한다
        #expect(store.state.isSubmitEnabled)
        await store.send(.view(.reviewTapped)) {
            $0.phase = .summary
        }
        await store.finish()
    }

    @Test("마지막 축을 채우면 완료 토스트가 뜨고 2초 뒤 자동으로 사라진다")
    func completionToastShowsOnTransitionAndAutoDismisses() async {
        let clock = TestClock()
        var state = GuestFeedbackFeature.State(token: "t1")
        state.entry = .fixture()
        state.phase = .evaluating
        state.startedEvaluation = true
        state.isImmersiveWatching = false
        for axis in AttitudeAxis.allFive.dropLast() {
            state.ratings[axis.code] = RatingDraft(level: 1, comment: "")
        }
        let last = AttitudeAxis.allFive.last!
        state.activeAxis = last
        let store = TestStore(initialState: state) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = .mock()
            $0.guestFeedbackLocalStore = .inMemory()
            $0.continuousClock = clock
        }

        // 마지막 축을 채우는 전이 순간 → 토스트 on
        await store.send(.view(.levelSelected(2))) {
            $0.ratings[last.code] = RatingDraft(level: 2, comment: "")
            $0.savingAxisCode = last.code
            $0.isCompletionToastVisible = true
        }
        await clock.advance(by: .milliseconds(500))   // debounce 저장 완료
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
        }
        await clock.advance(by: .milliseconds(1500))  // 토스트 타이머 누적 2초 도달
        await store.receive(\.inner.completionToastExpired) {
            $0.isCompletionToastVisible = false
        }

        // 이미 전부 평가된 뒤 레벨만 바꾸면 다시 뜨지 않는다
        await store.send(.view(.levelSelected(3))) {
            $0.ratings[last.code] = RatingDraft(level: 3, comment: "")
            $0.savingAxisCode = last.code
        }
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.inner.draftSaved) {
            $0.savingAxisCode = nil
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
            // «다시보기» 문구 그대로 처음부터 — 이동 명령(토큰)까지 실어 보낸다.
            $0.playback.seekToken = 1
            $0.playback.isPlaying = true
        }
    }
}
