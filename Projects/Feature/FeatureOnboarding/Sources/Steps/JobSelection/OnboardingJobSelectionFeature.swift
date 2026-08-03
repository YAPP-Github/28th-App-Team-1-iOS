//
//  OnboardingJobSelectionFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainJobInterface

// @lat: [[onboarding#직군 선택]]
/// 온보딩 STEP 1 — 직군 선택. 코디네이터(OnboardingFeature) 스택의 첫 화면.
/// 선택 결과는 delegate(.continueRequested(jobRole:))로 코디네이터에 올린다.
@Reducer
public struct OnboardingJobSelectionFeature {
    @ObservableState
    public struct State: Equatable {
        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 타이틀의 사용자 닉네임 — 코디네이터가 주입한다.
        public var userName: String
        public var jobs: [Job] = []
        public var selectedJobID: Job.ID?
        // TODO: 면접 위저드 리팩 때 제거 — 전역 로딩(NetworkActivity + AppView LoadingModal)과 중복이다.
        // 지금은 못 지운다: 이 위저드는 `fullScreenCover` 로 떠서, overlay 기반인 전역 모달이 그 아래 깔린다.
        // 화면을 인라인 루트로 올리거나 모달을 window 레벨로 올린 뒤 지울 것 (Auth 쪽은 이미 제거됨).
        public var isLoading = false
        /// draft 복원 시 미리 선택할 직군(jobRole) — 목록 로드 후 매칭해 selectedJobID 로 확정한다.
        public var preselectedJobRole: String?

        public var isContinueEnabled: Bool { selectedJobID != nil }

        public init(userName: String = "", step: Int = 1, totalSteps: Int = 5, preselectedJobRole: String? = nil) {
            self.userName = userName
            self.step = step
            self.totalSteps = totalSteps
            self.preselectedJobRole = preselectedJobRole
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedBack
            case userTappedClose
            case userTappedJob(Job.ID)
            case userTappedContinue
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            case jobsLoaded([Job])
            case jobsLoadFailed
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 하단 [이전으로] — 이 화면이 위저드 루트라 되돌아갈 스텝이 없다. 처리는 코디네이터 몫
            /// (지금은 위저드 이탈). 다른 스텝과 같은 이름을 쓰는 이유: 앞에 스텝이 붙으면
            /// 코디네이터 한 줄만 pop 으로 바뀌고 이 화면은 안 바뀐다.
            case backRequested
            /// 직군 선택 완료 — 다음 스텝으로. jobRole 은 서버 enum 값(예: "BACKEND").
            case continueRequested(jobRole: String)
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

    @Dependency(\.jobClient) var jobClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)
            case let .inner(action):
                return reduceInner(&state, action)
            case .delegate:
                return .none
            }
        }
    }

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            guard state.jobs.isEmpty, !state.isLoading else { return .none }
            state.isLoading = true
            return .run { send in
                await send(.inner(.jobsLoaded(try await jobClient.jobs())))
            } catch: { _, send in
                await send(.inner(.jobsLoadFailed))
            }

        case .userTappedBack:
            return .send(.delegate(.backRequested))

        case .userTappedClose:
            return .send(.delegate(.closeRequested))

        case let .userTappedJob(id):
            state.selectedJobID = id
            return .none

        case .userTappedContinue:
            guard let id = state.selectedJobID,
                  let jobRole = state.jobs.first(where: { $0.id == id })?.jobRole
            else { return .none }
            return .send(.delegate(.continueRequested(jobRole: jobRole)))
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .jobsLoaded(jobs):
            state.isLoading = false
            state.jobs = jobs
            // draft 복원: 저장된 jobRole 을 목록에서 찾아 미리 선택한다.
            if state.selectedJobID == nil, let role = state.preselectedJobRole {
                state.selectedJobID = jobs.first(where: { $0.jobRole == role })?.id
            }
            return .none

        case .jobsLoadFailed:
            // TODO: 실패 UX 디자인 미정 — 우선 로딩만 해제한다.
            state.isLoading = false
            return .none
        }
    }
}
