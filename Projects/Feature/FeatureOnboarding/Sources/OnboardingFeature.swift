//
//  OnboardingFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture

// @lat: [[onboarding#코디네이터]]
/// 온보딩 위저드 코디네이터. STEP 1(직군 선택)을 루트로 두고, 이후 스텝은 `path`(StackState)로 push 한다.
/// 각 스텝의 delegate 만 매칭해 공유 데이터(OnboardingData)를 누적하고 다음 스텝으로 전환한다 (D5).
/// 스텝 자체 간 직접 의존은 없다 — 조립은 여기서만 (도메인 내 navigation = Path/StackState).
@Reducer
public struct OnboardingFeature {
    @Reducer
    public enum Path {
        /// STEP 2+ 자리표시. 실제 스텝이 오면 case 를 추가한다 (예: case career(OnboardingCareerFeature)).
        case placeholder(OnboardingPlaceholderStepFeature)
    }

    // @Reducer enum 이 생성하는 Path.State 는 Equatable 을 자동 채택하지 않는다 —
    // StackState<Path.State> 를 담는 코디네이터 State 의 Equatable 합성을 위해 명시한다.

    @ObservableState
    public struct State: Equatable {
        /// STEP 1 — 루트 화면(직군 선택).
        public var jobSelection: OnboardingJobSelectionFeature.State
        /// STEP 2+ 네비게이션 스택.
        public var path = StackState<Path.State>()
        /// 스텝을 거치며 누적되는 공유 페이로드.
        public var data: OnboardingData

        public init(userName: String = "") {
            self.data = OnboardingData(userName: userName)
            self.jobSelection = OnboardingJobSelectionFeature.State(userName: userName, step: 1)
        }
    }

    public enum Action {
        case jobSelection(OnboardingJobSelectionFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 온보딩 종료(이탈 또는 완료) — dismiss 는 코디네이터(AppFeature)가 처리한다.
            case dismiss
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.jobSelection, action: \.jobSelection) {
            OnboardingJobSelectionFeature()
        }

        Reduce { state, action in
            switch action {
            // STEP 1 완료 → 직군 저장 후 다음 스텝 push.
            case let .jobSelection(.delegate(.continueRequested(jobRole))):
                state.data.jobRole = jobRole
                state.path.append(
                    .placeholder(.init(step: 2, totalSteps: state.jobSelection.totalSteps))
                )
                return .none

            case .jobSelection(.delegate(.closeRequested)):
                return .send(.delegate(.dismiss))

            case .jobSelection:
                return .none

            // 스텝 템플릿(자리표시)의 신호 처리 — 실제 스텝이 붙으면 case 별로 확장.
            case let .path(.element(id: _, action: .placeholder(.delegate(action)))):
                switch action {
                case .continueRequested:
                    // TODO: 다음 스텝 push (state.path.append(...)). 마지막 스텝이면 제출 후 .delegate(.dismiss).
                    return .none
                case .backRequested:
                    _ = state.path.popLast()
                    return .none
                case .closeRequested:
                    return .send(.delegate(.dismiss))
                }

            case .path:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

// Path.State(=@Reducer enum 생성물)에 Equatable 합성 — 모든 스텝 State 가 Equatable 이므로 성립.
extension OnboardingFeature.Path.State: Equatable {}
