//
//  GuestFeedbackReducer.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import ComposableArchitecture
import DomainFeedbackInterface
import Foundation

// @lat: [[feedback#G4 게스트 평가]]
// GuestFeedbackFeature 의 리듀서 본문 — 타입 선언(Feature 파일)과 분리한 별도 파일.
// cyclomatic-complexity 에러는 reduceView 를 카테고리 서브함수로 쪼개 해소했다(한 파일로도 가능).
// 파일 분리는 다화면(7뷰) Feature 리듀서를 위한 의도적 구성 선택으로, 비차단 length 경고만 피한다.
// body 가 호출하는 reduceView·reduceInner·enter·submit 만 internal, 나머지 헬퍼는 file-private.
extension GuestFeedbackFeature {
    private enum CancelID { case draftDebounce }

    // MARK: - View

    func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            return reduceOnAppear(&state)

        case .startTapped, .nicknameNextTapped, .nicknameSheetDismissed,
             .reviewTapped, .summaryCardTapped, .rewatchTapped, .submitTapped:
            return reduceStep(&state, action)

        case .axisSelected, .expandVideoTapped, .levelSelected,
             .commentEditTapped, .commentDoneTapped, .commentDismissed:
            return reduceEvaluation(&state, action)

        // 스키마 예약 필드 overallFeedback 의 휴면 경로 — 현재 디자인엔 이 필드를 바인딩하는 뷰가 없다(재도입 대비).
        case .binding(\.overallFeedback):
            state.overallFeedback = GuestTextRules.sanitized(state.overallFeedback, limit: GuestTextRules.overallLimit)
            guard state.phase == .evaluating else { return .none }
            return debouncedDraftSave(state)

        case .binding(\.commentDraft):
            state.commentDraft = GuestTextRules.sanitized(state.commentDraft, limit: GuestTextRules.axisCommentLimit)
            return .none

        case .binding:
            return .none
        }
    }

    /// 화면 첫 로드 — draft 복원 후 enter.
    private func reduceOnAppear(_ state: inout State) -> Effect<Action> {
        guard state.phase == .loading, state.entry == nil else { return .none }
        // draft 를 동기 반영한 뒤 enter — entryLoaded 시점의 phase 분기가 레이스 없이 결정된다.
        if let draft = localStore.loadDraft(state.token) {
            state.nickname = draft.nickname
            state.ratings = draft.ratings
            state.overallFeedback = draft.overallFeedback
            state.startedEvaluation = draft.startedEvaluation
        }
        return enter(&state)
    }

    /// 선형 플로우 전진 — 온보딩에서 닉네임 시트 열고/확정, 평가→요약, 요약→제출 확인.
    private func reduceStep(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .startTapped:
            // 온보딩 위에 닉네임 입력 시트를 연다 — phase 는 온보딩에 머문다.
            guard state.phase == .onboarding else { return .none }
            state.isEnteringNickname = true
            return .none

        case .nicknameNextTapped:
            // 닉네임 확정 → 시트 닫고 시작 연출로 (loading→evaluating).
            guard state.isEnteringNickname else { return .none }
            state.isEnteringNickname = false
            state.phase = .starting
            return .merge(saveDraftNow(state), startVideo())

        case .nicknameSheetDismissed:
            // 스와이프 취소 — 온보딩에 머물러 재진입 가능.
            state.isEnteringNickname = false
            return .none

        case .reviewTapped:
            guard state.isSubmitEnabled else { return .none }
            state.phase = .summary
            return .none

        case .summaryCardTapped(let axis):
            // 요약 카드 탭 = 해당 축 바로 수정 — 평가 카드 모드로 돌아간다 (시안 «항목을 누르면 바로 수정»).
            guard state.phase == .summary else { return .none }
            state.activeAxis = axis
            state.isImmersiveWatching = false
            state.phase = .evaluating
            return .none

        case .rewatchTapped:
            // 요약 «영상 다시보기» — 평가 몰입 시청으로 돌아간다.
            guard state.phase == .summary else { return .none }
            state.isImmersiveWatching = true
            state.phase = .evaluating
            return .none

        case .submitTapped:
            guard state.isSubmitEnabled else { return .none }
            state.confirmDialog = .submitConfirm
            return .none

        default:
            return .none
        }
    }

    /// 평가 입력 — 축 세그먼트 전환, 레벨 칩, 코멘트 카드 편집.
    private func reduceEvaluation(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .axisSelected(let axis):
            guard state.phase == .evaluating else { return .none }
            state.activeAxis = axis
            state.commentEditing = false
            state.isImmersiveWatching = false   // 몰입 시청 중 축 탭 = 평가 카드 모드 진입
            return .none

        case .expandVideoTapped:
            guard state.phase == .evaluating else { return .none }
            state.isImmersiveWatching = true
            return .none

        case .levelSelected(let level):
            guard state.canEvaluate, let axis = state.activeAxis, (1...4).contains(level) else { return .none }
            let existing = state.ratings[axis.code]
            state.ratings[axis.code] = RatingDraft(level: level, comment: existing?.comment ?? "")
            state.savingAxisCode = axis.code
            return debouncedDraftSave(state)

        case .commentEditTapped:
            guard let axis = state.activeAxis else { return .none }
            state.commentDraft = state.ratings[axis.code]?.comment ?? ""
            state.commentEditing = true
            return .none

        case .commentDoneTapped:
            guard let axis = state.activeAxis else { return .none }
            let level = state.ratings[axis.code]?.level
            state.ratings[axis.code] = RatingDraft(level: level, comment: state.commentDraft)
            state.commentEditing = false
            return saveDraftNow(state)

        case .commentDismissed:
            state.commentEditing = false
            return .none

        default:
            return .none
        }
    }

    // MARK: - Inner

    func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case .entryLoaded(.success(let entry)):
            state.entry = entry
            return reduceEntryGate(&state, entry)

        case .entryLoaded(.failure(let error)):
            return reduceEnterFailure(&state, error)

        case .videoReady:
            guard state.phase == .starting else { return .none }
            state.startedEvaluation = true
            state.activeAxis = state.entry?.axes.first
            state.phase = .evaluating
            return saveDraftNow(state)

        case .draftSaved:
            state.savingAxisCode = nil
            return .none

        case .submitFinished(let result):
            return reduceSubmitFinished(&state, result)
        }
    }

    /// 게이트별 착지 화면 — OPEN 은 이어하기 여부로, FULL 은 시청 전용 평가로, 나머지는 차단.
    private func reduceEntryGate(_ state: inout State, _ entry: GuestFeedbackEntry) -> Effect<Action> {
        switch entry.gate {
        case .open:
            if state.startedEvaluation {
                state.phase = .evaluating
                state.activeAxis = entry.axes.first   // 이어하기 재개 — 첫 축을 활성 세그먼트로
            } else {
                state.phase = .onboarding
            }
        case .full:
            state.phase = .evaluating   // 시청 전용 — canEvaluate 가 submissionOpen 으로 막는다
            state.activeAxis = entry.axes.first
        case .private:
            state.phase = .gateClosed(.private)
        case .expired:
            state.phase = .gateClosed(.expired)
        case .alreadySubmitted:
            state.phase = .gateClosed(.alreadySubmitted)
        case .unknown:
            state.phase = .gateClosed(.unknown)
        }
        return .none
    }

    /// 제출 결과 분기 — 성공은 완료+draft 삭제, 실패는 에러별 차단/강등/알럿.
    private func reduceSubmitFinished(
        _ state: inout State,
        _ result: Result<GuestSubmissionReceipt, GuestFeedbackError>
    ) -> Effect<Action> {
        state.isSubmitting = false
        switch result {
        case .success:
            state.phase = .completed
            return .run { [token = state.token] _ in
                localStore.clearDraft(token)
            }
        case .failure(let error):
            return reduceSubmitFailure(&state, error)
        }
    }

    /// 제출 실패 분기 — 비공개/기제출은 차단, 정원 마감은 시청 전용 강등, 그 외는 알럿.
    private func reduceSubmitFailure(_ state: inout State, _ error: GuestFeedbackError) -> Effect<Action> {
        switch error {
        case .closed:
            state.phase = .gateClosed(.private)
            return .none
        case .capacityFull:
            // 제출 도중 정원 마감 — 시청 전용으로 강등 (PRD §2-5)
            state.entry?.submissionOpen = false
            state.alert = .plain(message: GuestFeedbackError.capacityFull.userMessage)
            return .none
        case .alreadySubmitted:
            state.phase = .gateClosed(.alreadySubmitted)
            return .run { [token = state.token] _ in
                localStore.clearDraft(token)
            }
        case .invalidToken:
            state.phase = .gateClosed(.invalidToken)
            return .none
        case .invalidSubmission, .underlying:
            state.alert = .plain(message: error.userMessage)
            return .none
        }
    }

    /// 진입 실패 분기 — 영구 상태 에러는 재시도 알럿이 아니라 차단 화면으로 보낸다 (재시도가 무의미).
    private func reduceEnterFailure(_ state: inout State, _ error: GuestFeedbackError) -> Effect<Action> {
        switch error {
        case .invalidToken:
            state.phase = .gateClosed(.invalidToken)
            return .none
        case .closed:
            state.phase = .gateClosed(.private)
            return .none
        case .alreadySubmitted:
            state.phase = .gateClosed(.alreadySubmitted)
            return .run { [token = state.token] _ in
                localStore.clearDraft(token)
            }
        case .capacityFull:
            // entry 데이터가 없어 시청 전용을 제공할 수 없다 — 일반 차단 문구가 안전.
            state.phase = .gateClosed(.unknown)
            return .none
        case .invalidSubmission, .underlying:
            state.alert = .enterFailed(message: error.userMessage)
            return .none
        }
    }

    // MARK: - Effects

    func enter(_ state: inout State) -> Effect<Action> {
        state.phase = .loading
        return .run { [token = state.token] send in
            do {
                let entry = try await client.enter(token)
                await send(.inner(.entryLoaded(.success(entry))))
            } catch is CancellationError {
                // 구조적 취소는 실패가 아니다 — 아무 것도 보내지 않는다.
            } catch {
                await send(.inner(.entryLoaded(.failure(.wrap(error)))))
            }
        }
    }

    func submit(_ state: inout State) -> Effect<Action> {
        guard let entry = state.entry else { return .none }
        state.isSubmitting = true
        let submission = GuestSubmission(
            nickname: state.nickname.isEmpty ? nil : state.nickname,
            ratings: entry.axes.compactMap { axis -> GuestRating? in
                guard let draft = state.ratings[axis.code], let level = draft.level else { return nil }
                return GuestRating(
                    axisCode: axis.code,
                    level: level,
                    comment: draft.comment.isEmpty ? nil : draft.comment
                )
            },
            overallFeedback: state.overallFeedback.isEmpty ? nil : state.overallFeedback
        )
        return .run { [token = state.token] send in
            do {
                let receipt = try await client.submit(token, submission)
                await send(.inner(.submitFinished(.success(receipt))))
            } catch is CancellationError {
            } catch {
                await send(.inner(.submitFinished(.failure(.wrap(error)))))
            }
        }
    }

    /// 시작 화면 연출 — 짧은 대기 후 평가로 넘긴다. (실 영상 프리페치는 Task 후속.)
    private func startVideo() -> Effect<Action> {
        .run { send in
            try? await clock.sleep(for: .seconds(1))
            await send(.inner(.videoReady))
        }
    }

    private func saveDraftNow(_ state: State) -> Effect<Action> {
        .run { [token = state.token, draft = state.draft] _ in
            localStore.saveDraft(token, draft)
        }
    }

    private func debouncedDraftSave(_ state: State) -> Effect<Action> {
        .run { [token = state.token, draft = state.draft] send in
            try await clock.sleep(for: .milliseconds(500))
            localStore.saveDraft(token, draft)
            await send(.inner(.draftSaved))
        }
        .cancellable(id: CancelID.draftDebounce, cancelInFlight: true)
    }
}
