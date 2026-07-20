//
//  OnboardingPlaceholderStepFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture

// @lat: [[onboarding#스텝 템플릿]]
/// 온보딩 STEP 2+ 자리표시 템플릿. 실제 스텝 디자인이 오면 이 파일을 복사해
/// Onboarding<StepName>Feature 로 이름만 바꿔 채운다 (구조는 동일: view/inner/delegate 3분류).
/// 코디네이터가 step/totalSteps 를 주입하고, 완료·뒤로는 delegate 로 올린다.
@Reducer
public struct OnboardingPlaceholderStepFeature {
    @ObservableState
    public struct State: Equatable {
        public let step: Int
        public let totalSteps: Int
        /// 실제 스텝에서 이 화면이 수집·표시할 데이터로 대체한다.
        public var title: String

        public init(step: Int, totalSteps: Int, title: String = "다음 스텝") {
            self.step = step
            self.totalSteps = totalSteps
            self.title = title
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        public enum View: Equatable, Sendable {
            case userTappedBack
            case userTappedClose
            case userTappedContinue
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 이 스텝 완료 — 코디네이터가 다음 스텝을 push.
            case continueRequested
            /// 뒤로 — 코디네이터가 스택을 pop.
            case backRequested
            /// 온보딩 이탈(X).
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.userTappedBack):
                return .send(.delegate(.backRequested))
            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))
            case .view(.userTappedContinue):
                return .send(.delegate(.continueRequested))
            case .delegate:
                return .none
            }
        }
    }
}
