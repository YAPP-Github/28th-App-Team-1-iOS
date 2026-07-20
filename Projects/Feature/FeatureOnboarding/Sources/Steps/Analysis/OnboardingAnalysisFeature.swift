//
//  OnboardingAnalysisFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import DomainInterviewInterface

// @lat: [[onboarding#분석]]
/// 온보딩 STEP 6 — 분석 중/분석 완료 (Figma «6. 분석 중» 1609:9019 · «6.1 분석 완료» 1609:9075).
/// 앞선 스텝들이 채운 OnboardingData 를 InterviewConfig 로 변환해 세션 생성(PRD §3.8 — S0~S3 일괄 수집)을
/// 요청하고, PROCESSING 이면 status 를 폴링해 READY 를 기다린다. READY 면 완료 화면을 잠시 보여준 뒤
/// delegate(.completed(sessionId:))로 세션을 코디네이터에 넘긴다 — dismiss·Part2 진입은 코디네이터 몫.
@Reducer
public struct OnboardingAnalysisFeature {
    /// 세션 준비 상태 폴링 주기 — InterviewClient 가이드(3~5초)의 하한.
    static let pollInterval: Duration = .seconds(3)
    /// 완료 화면 노출 유지 시간 — 지나면 자동으로 delegate(.completed)를 올린다.
    static let completionHoldDuration: Duration = .seconds(2)
    /// 세션 생성/폴링 실패 문구 — 재시도 없음(PRD §3.1), X 로 이탈해 처음부터.
    static let failureMessage = "면접 준비에 실패했어요.\n잠시 후 다시 시도해 주세요."
    /// 수집 데이터가 불완전해 세션 입력을 만들지 못한 경우 — 위저드 순서상 정상 진입이면 발생하지 않는다.
    static let configMissingMessage = "면접 준비에 필요한 정보가 부족해요.\n처음부터 다시 시도해 주세요."

    @ObservableState
    public struct State: Equatable {
        /// 화면 하위 상태 — 분석 중 → 완료 / 실패. 별도 화면 push 없이 이 값으로 전환한다.
        public enum Phase: Equatable, Sendable {
            case analyzing
            case completed
            /// 세션 생성·폴링 실패. 사용자 노출 문구를 동봉한다.
            case failed(message: String)
        }

        /// 앞선 스텝들이 수집한 공유 페이로드 — 세션 생성 입력. 코디네이터가 주입한다.
        public var data: OnboardingData
        public var phase: Phase = .analyzing
        /// 생성된 세션 id — READY 후 delegate 로 코디네이터에 넘긴다.
        public var sessionId: Int?
        /// onAppear 재진입 가드 — 분석 effect 중복 실행 방지.
        public var hasStartedAnalysis = false

        public init(data: OnboardingData) {
            self.data = data
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedClose
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// POST /interview/sessions 접수 응답 (202 PROCESSING).
            case sessionCreated(InterviewSessionCreated)
            /// GET /interview/sessions/{id}/status 폴링 응답.
            case statusPolled(InterviewSessionStatus)
            /// 세션 생성·폴링 실패 — 실패 화면으로 전환.
            case analysisFailed(message: String)
            /// 완료 화면 유지 시간 경과 — 온보딩 완료 신호를 올릴 시점.
            case completionHoldFinished
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 온보딩 전체 완료 — 준비된 세션 id 를 넘긴다. 화면 전환(Part2 진입)은 코디네이터가 처리.
            case completed(sessionId: Int)
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

    private enum CancelID { case session }

    @Dependency(\.interviewClient) var interviewClient
    @Dependency(\.continuousClock) var clock

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
            guard !state.hasStartedAnalysis else { return .none }
            state.hasStartedAnalysis = true
            guard let config = state.data.interviewConfig() else {
                return .send(.inner(.analysisFailed(message: Self.configMissingMessage)))
            }
            return .run { send in
                await send(.inner(.sessionCreated(try await interviewClient.createSession(config))))
            } catch: { _, send in
                await send(.inner(.analysisFailed(message: Self.failureMessage)))
            }
            .cancellable(id: CancelID.session)

        case .userTappedClose:
            return .send(.delegate(.closeRequested))
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .sessionCreated(created):
            state.sessionId = created.sessionId
            return pollStatus(sessionId: created.sessionId)

        case let .statusPolled(status):
            switch status.status {
            case .ready:
                state.phase = .completed
                return .run { send in
                    try await clock.sleep(for: Self.completionHoldDuration)
                    await send(.inner(.completionHoldFinished))
                }
                .cancellable(id: CancelID.session)
            case .processing:
                guard let sessionId = state.sessionId else { return .none }
                return .run { send in
                    try await clock.sleep(for: Self.pollInterval)
                    await send(.inner(.statusPolled(try await interviewClient.sessionStatus(sessionId))))
                } catch: { _, send in
                    await send(.inner(.analysisFailed(message: Self.failureMessage)))
                }
                .cancellable(id: CancelID.session)
            case .failed:
                state.phase = .failed(message: Self.failureMessage)
                return .none
            }

        case let .analysisFailed(message):
            state.phase = .failed(message: message)
            return .none

        case .completionHoldFinished:
            guard let sessionId = state.sessionId else { return .none }
            return .send(.delegate(.completed(sessionId: sessionId)))
        }
    }

    /// 접수(sessionCreated) 후 첫 상태 조회 — PROCESSING 이면 이후 statusPolled 가 폴링을 잇는다.
    private func pollStatus(sessionId: Int) -> Effect<Action> {
        .run { send in
            await send(.inner(.statusPolled(try await interviewClient.sessionStatus(sessionId))))
        } catch: { _, send in
            await send(.inner(.analysisFailed(message: Self.failureMessage)))
        }
        .cancellable(id: CancelID.session)
    }
}
