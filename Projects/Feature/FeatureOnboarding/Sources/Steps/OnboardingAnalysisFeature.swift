//
//  OnboardingAnalysisFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture

// @lat: [[onboarding#분석]]
/// 온보딩 STEP 6 — 분석 중/분석 완료 (Figma «6. 분석 중» 1609:9019 · «6.1 분석 완료» 1609:9075).
/// 앞선 스텝들이 채운 OnboardingData 를 입력으로 분석을 돌리고(현재는 데모용 clock 시뮬레이션),
/// 완료 화면을 잠시 보여준 뒤 delegate(.completed)로 온보딩 전체 완료를 코디네이터에 올린다.
/// 화면에 CTA 버튼이 없어(디자인 확인) 완료 전환은 자동이다 — dismiss·메인 진입은 코디네이터 몫.
@Reducer
public struct OnboardingAnalysisFeature {
    /// 데모용 분석 소요 시간 — Domain 에 제출/분석 Client 가 생기면 실제 응답 대기로 대체한다.
    static let analysisDuration: Duration = .seconds(3)
    /// 완료 화면 노출 유지 시간 — 지나면 자동으로 delegate(.completed)를 올린다.
    static let completionHoldDuration: Duration = .seconds(2)

    @ObservableState
    public struct State: Equatable {
        /// 화면 하위 상태 — 분석 중 → 분석 완료. 별도 화면 push 없이 이 값으로 전환한다.
        public enum Phase: Equatable, Sendable {
            case analyzing
            case completed
        }

        /// 앞선 스텝들이 수집한 공유 페이로드 — 분석(서버 제출) 입력. 코디네이터가 주입한다.
        public var data: OnboardingData
        public var phase: Phase = .analyzing
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
            /// 분석 완료 — 완료 화면(phase == .completed)으로 전환.
            case analysisCompleted
            /// 완료 화면 유지 시간 경과 — 온보딩 완료 신호를 올릴 시점.
            case completionHoldFinished
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 온보딩 전체 완료 — 화면 전환(dismiss·메인 진입)은 코디네이터가 처리.
            case completed
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

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
            // TODO: API 연결 — OnboardingData 제출/분석 Client 가 Domain 에 생기면
            //       clock 시뮬레이션을 실제 요청·폴링으로 교체한다.
            return .run { send in
                try await clock.sleep(for: Self.analysisDuration)
                await send(.inner(.analysisCompleted))
            }

        case .userTappedClose:
            return .send(.delegate(.closeRequested))
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case .analysisCompleted:
            state.phase = .completed
            return .run { send in
                try await clock.sleep(for: Self.completionHoldDuration)
                await send(.inner(.completionHoldFinished))
            }

        case .completionHoldFinished:
            return .send(.delegate(.completed))
        }
    }
}
