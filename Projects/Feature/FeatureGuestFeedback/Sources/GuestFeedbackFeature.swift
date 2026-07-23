//
//  GuestFeedbackFeature.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainFeedbackInterface
import Foundation

// @lat: [[feedback#G4 게스트 평가]]
// 게스트가 공유 토큰으로 진입해 태도 항목을 4단계 척도로 평가·제출하는 G4 단일 리듀서.
// 화면 전환은 phase 하나로 — 선형 플로우(온보딩→시작→평가→요약→완료)라 StackState 를 두지 않는다.
// 닉네임 입력은 별도 phase 가 아니라 온보딩 위에 올라오는 바텀 시트다(isEnteringNickname 로 구동).
@Reducer
public struct GuestFeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        public let token: String
        public var phase: Phase = .loading
        public var entry: GuestFeedbackEntry?
        public var nickname = ""
        public var ratings: [String: RatingDraft] = [:]
        // 스키마 호환용으로 유지 — 현재 디자인은 전역 코멘트 UI 없음(축별 코멘트가 대체).
        // 재도입 시 뷰가 `$store.overallFeedback` 를 바인딩한다.
        public var overallFeedback = ""
        // 온보딩 위 닉네임 입력 바텀 시트의 표출 여부(별도 phase 아님).
        public var isEnteringNickname = false
        public var startedEvaluation = false
        public var activeAxis: AttitudeAxis?
        // 평가 화면 표시 모드 — true=몰입(풀블리드 영상+축 바만), false=카드(영상 카드+평가 카드).
        // 최초 진입·영상 다시보기는 몰입, 축 탭·요약 카드 수정 진입은 카드로 연다.
        public var isImmersiveWatching = true
        public var commentEditing = false     // 활성 축의 코멘트 카드 펼침 여부
        public var commentDraft = ""          // 코멘트 편집 버퍼 (저장 시 ratings[activeAxis].comment)
        public var isSubmitting = false
        // 저장 인디케이터 구동 — levelSelected 로 debounce 저장이 도는 축 코드(draftSaved 가 해제).
        public var savingAxisCode: String?
        @Presents public var confirmDialog: ConfirmationDialogState<ConfirmDialog>?
        @Presents public var alert: AlertState<Alert>?

        public init(token: String) {
            self.token = token
        }

        /// FULL(시청 전용)·제출 중이면 평가 입력을 막는다.
        public var canEvaluate: Bool {
            entry?.submissionOpen == true && !isSubmitting
        }

        /// 제출 성립 조건 (PRD §2-3): 지정 항목 전부 level 선택.
        public var isSubmitEnabled: Bool {
            guard let entry, entry.submissionOpen, !isSubmitting, !entry.axes.isEmpty else { return false }
            return entry.axes.allSatisfy { ratings[$0.code]?.level != nil }
        }

        var draft: GuestFeedbackDraft {
            GuestFeedbackDraft(
                nickname: nickname,
                ratings: ratings,
                overallFeedback: overallFeedback,
                startedEvaluation: startedEvaluation
            )
        }
    }

    public enum Phase: Equatable, Sendable {
        case loading
        case onboarding
        case starting
        case evaluating
        case summary
        case completed
        case gateClosed(GateReason)
    }

    public enum GateReason: Equatable, Sendable {
        case `private`
        case expired
        case alreadySubmitted
        case invalidToken
        case unknown
    }

    public enum ConfirmDialog: Equatable, Sendable {
        case confirmSubmit
    }

    public enum Alert: Equatable, Sendable {
        case retryEnter
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        // TCA 구조적 액션 — 3분류 밖의 presentation 전용 케이스.
        case confirmDialog(PresentationAction<ConfirmDialog>)
        case alert(PresentationAction<Alert>)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        @CasePathable
        public enum View: BindableAction, Sendable {
            case binding(BindingAction<State>)
            case onAppear
            case startTapped            // 온보딩 → 닉네임 시트 표출
            case nicknameNextTapped     // 닉네임 확정 → starting
            case nicknameSheetDismissed // 닉네임 시트 스와이프 취소 → 온보딩 유지
            case axisSelected(AttitudeAxis)   // 세그먼트 탭 전환 (몰입 중이면 카드 모드로)
            case expandVideoTapped            // 카드 영상 ⛶ → 몰입 시청 복귀
            case levelSelected(Int)           // 레벨 칩
            case commentEditTapped            // 코멘트 카드 열기
            case commentDoneTapped            // 코멘트 저장·닫기
            case commentDismissed             // 코멘트 닫기(저장 없이)
            case reviewTapped                 // 평가 → summary
            case summaryCardTapped(AttitudeAxis) // 요약 카드 탭 → 해당 축 수정(평가 카드 모드)
            case rewatchTapped                // 요약 «영상 다시보기» → 평가 몰입 시청
            case submitTapped                 // summary 전송 → 확인 다이얼로그
        }

        /// effect 결과·내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Sendable {
            case entryLoaded(Result<GuestFeedbackEntry, GuestFeedbackError>)
            case submitFinished(Result<GuestSubmissionReceipt, GuestFeedbackError>)
            case videoReady                    // starting 연출 종료 → evaluating
            case draftSaved                    // debounce draft 저장 완료 → 저장 인디케이터 해제
        }

        /// 부모(코디네이터·Example 루트) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Sendable {
            case dismissed
        }
    }

    @Dependency(\.guestFeedbackClient) var client
    @Dependency(\.guestFeedbackLocalStore) var localStore
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        Reduce { state, action in
            switch action {
            case .view(let viewAction):
                return reduceView(&state, viewAction)
            case .inner(let innerAction):
                return reduceInner(&state, innerAction)
            case .confirmDialog(.presented(.confirmSubmit)):
                return submit(&state)
            case .confirmDialog:
                return .none
            case .alert(.presented(.retryEnter)):
                return enter(&state)
            case .alert:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$confirmDialog, action: \.confirmDialog)
        .ifLet(\.$alert, action: \.alert)
    }
}
