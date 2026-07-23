//
//  GuestFeedbackSubmitTests.swift
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

/// 5개 축 전부 평가된 상태 — 제출 활성 조건 픽스처.
private let allRated: [String: RatingDraft] = Dictionary(
    uniqueKeysWithValues: AttitudeAxis.allFive.map { ($0.code, RatingDraft(level: 2, comment: "")) }
)

@MainActor
struct GuestFeedbackSubmitTests {
    private func makeReadyStore(
        client: GuestFeedbackClient = .mock(),
        localStore: GuestFeedbackLocalStore = .inMemory(),
        ratings: [String: RatingDraft] = allRated
    ) -> TestStoreOf<GuestFeedbackFeature> {
        var state = GuestFeedbackFeature.State(token: "t1")
        state.entry = .fixture()
        state.phase = .evaluating
        state.startedEvaluation = true
        state.ratings = ratings
        return TestStore(initialState: state) {
            GuestFeedbackFeature()
        } withDependencies: {
            $0.guestFeedbackClient = client
            $0.guestFeedbackLocalStore = localStore
            $0.continuousClock = ImmediateClock()
        }
    }

    @Test("모든 지정 항목을 평가해야 제출이 활성화된다")
    func submitRequiresAllAxesRated() async {
        var partial = allRated
        partial.removeValue(forKey: "VOICE")
        let store = makeReadyStore(ratings: partial)

        #expect(store.state.isSubmitEnabled == false)
        await store.send(.view(.submitTapped))   // 비활성 — 상태 변화 없음

        let ready = makeReadyStore()
        #expect(ready.state.isSubmitEnabled == true)
    }

    @Test("제출 확인 후 성공하면 완료 화면으로 가고 임시저장을 지운다")
    func submitSuccessCompletesAndClearsDraft() async {
        let localStore = GuestFeedbackLocalStore.inMemory()
        localStore.saveDraft("t1", GuestFeedbackDraft(nickname: "", ratings: [:], overallFeedback: "", startedEvaluation: true))
        let store = makeReadyStore(localStore: localStore)

        await store.send(.view(.submitTapped)) {
            $0.confirmDialog = .submitConfirm
        }
        await store.send(.confirmDialog(.presented(.confirmSubmit))) {
            $0.confirmDialog = nil
            $0.isSubmitting = true
        }
        await store.receive(\.inner.submitFinished) {
            $0.isSubmitting = false
            $0.phase = .completed
        }
        await store.finish()

        #expect(localStore.loadDraft("t1") == nil)
    }

    @Test("제출 payload 는 지정 항목 순서로, 빈 별칭·빈 코멘트는 nil 로 담는다")
    func submitBuildsPayloadFromDesignatedAxes() async {
        let captured = LockIsolated<GuestSubmission?>(nil)
        var client = GuestFeedbackClient.mock()
        client.submit = { _, submission in
            captured.setValue(submission)
            return GuestSubmissionReceipt(submissionID: 1, submittedAt: Date(timeIntervalSince1970: 1_784_500_000))
        }
        var ratings = allRated
        ratings["GAZE"] = RatingDraft(level: 3, comment: "가끔 피해요")
        let store = makeReadyStore(client: client, ratings: ratings)

        await store.send(.view(.submitTapped)) {
            $0.confirmDialog = .submitConfirm
        }
        await store.send(.confirmDialog(.presented(.confirmSubmit))) {
            $0.confirmDialog = nil
            $0.isSubmitting = true
        }
        await store.receive(\.inner.submitFinished) {
            $0.isSubmitting = false
            $0.phase = .completed
        }
        await store.finish()

        let submission = captured.value
        #expect(submission?.nickname == nil)   // 빈 별칭 → nil (서버가 지인1~4 자동 부여)
        #expect(submission?.overallFeedback == nil)
        #expect(submission?.ratings.map(\.axisCode) == AttitudeAxis.allFive.map(\.code))
        #expect(submission?.ratings.first == GuestRating(axisCode: "GAZE", level: 3, comment: "가끔 피해요"))
        #expect(submission?.ratings.last?.comment == nil)   // 빈 코멘트 → nil
    }

    @Test("409 정원 마감이면 시청 전용으로 강등하고 안내한다")
    func capacityFullDowngradesToViewingOnly() async {
        let store = makeReadyStore(client: .mock(submitError: .capacityFull))

        await store.send(.view(.submitTapped)) {
            $0.confirmDialog = .submitConfirm
        }
        await store.send(.confirmDialog(.presented(.confirmSubmit))) {
            $0.confirmDialog = nil
            $0.isSubmitting = true
        }
        await store.receive(\.inner.submitFinished) {
            $0.isSubmitting = false
            $0.entry?.submissionOpen = false
            $0.alert = .plain(message: "이미 4분이 참여했어요.")
        }
    }

    @Test(
        "409 비공개·기제출이면 차단 화면으로 전환한다",
        arguments: [
            (GuestFeedbackError.closed, GuestFeedbackFeature.GateReason.private),
            (GuestFeedbackError.alreadySubmitted, GuestFeedbackFeature.GateReason.alreadySubmitted)
        ]
    )
    func conflictErrorsCloseGate(error: GuestFeedbackError, reason: GuestFeedbackFeature.GateReason) async {
        let store = makeReadyStore(client: .mock(submitError: error))

        await store.send(.view(.submitTapped)) {
            $0.confirmDialog = .submitConfirm
        }
        await store.send(.confirmDialog(.presented(.confirmSubmit))) {
            $0.confirmDialog = nil
            $0.isSubmitting = true
        }
        await store.receive(\.inner.submitFinished) {
            $0.isSubmitting = false
            $0.phase = .gateClosed(reason)
        }
        await store.finish()
    }

    @Test("400 이면 알럿을 띄우고 입력을 유지한다")
    func validationErrorKeepsInput() async {
        let store = makeReadyStore(client: .mock(submitError: .invalidSubmission))

        await store.send(.view(.submitTapped)) {
            $0.confirmDialog = .submitConfirm
        }
        await store.send(.confirmDialog(.presented(.confirmSubmit))) {
            $0.confirmDialog = nil
            $0.isSubmitting = true
        }
        await store.receive(\.inner.submitFinished) {
            $0.isSubmitting = false
            $0.alert = .plain(message: "지정된 항목을 모두 평가해 주세요.")
        }
        #expect(store.state.ratings.count == 5)   // 입력 유지
        #expect(store.state.phase == .evaluating)
    }
}
