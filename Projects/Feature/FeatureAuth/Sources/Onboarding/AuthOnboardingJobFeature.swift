//
//  AuthOnboardingJobFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import DomainJobInterface

// @lat: [[auth#가입 플로우]]
/// 가입 온보딩 2 — 직군 선택. 직군·연차가 가입 플로우로 이관되며 면접 위저드에서 옮겨 왔다 —
/// 원본(FeatureOnboarding STEP1)은 위저드 재편 때 삭제됐고 여기가 단일 소스다. → [[onboarding#코디네이터]]
/// 선택 결과는 delegate(.continueRequested(jobRole:))로 코디네이터(AuthFeature)에 올린다.
@Reducer
public struct AuthOnboardingJobFeature {
    @ObservableState
    public struct State: Equatable {
        /// 프로그레스 바 분모 — 가입 온보딩 수집 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 타이틀의 사용자 이름 — 코디네이터가 이름 입력 결과를 주입한다.
        public var userName: String
        public var jobs: [Job] = []
        public var selectedJobID: Job.ID?

        public var isContinueEnabled: Bool { selectedJobID != nil }

        public init(userName: String = "", step: Int = 2, totalSteps: Int = 3) {
            self.userName = userName
            self.step = step
            self.totalSteps = totalSteps
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

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 직군 선택 완료 — 다음(연차)으로. jobRole 은 서버 enum 값(예: "BACKEND").
            case continueRequested(jobRole: String)
            /// 뒤로(하단 «이전으로») — 코디네이터가 스택을 pop.
            case backRequested
            /// 가입 온보딩 이탈(X) — 처리는 코디네이터 몫.
            case closeRequested
        }
    }

    @Dependency(\.jobClient) var jobClient

    /// 직군 목록 요청 취소 id — 재진입 시 앞 요청을 접어 중복 발사를 막는다(로딩 플래그 대용).
    private enum CancelID { case jobs }

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
        // 로딩 표시는 안 든다 — 전 API in-flight 를 AppView 가 전역 LoadingModal 로 덮는다(NetworkActivity).
        case .onAppear:
            guard state.jobs.isEmpty else { return .none }
            return .run { send in
                await send(.inner(.jobsLoaded(try await jobClient.jobs())))
            } catch: { _, send in
                await send(.inner(.jobsLoadFailed))
            }
            .cancellable(id: CancelID.jobs, cancelInFlight: true)

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
            state.jobs = jobs
            return .none

        case .jobsLoadFailed:
            // TODO: 실패 UX 디자인 미정 — 빈 목록으로 남는다.
            return .none
        }
    }
}
