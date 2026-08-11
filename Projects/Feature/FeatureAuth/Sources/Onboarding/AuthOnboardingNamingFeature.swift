//
//  AuthOnboardingNamingFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

// @lat: [[auth#가입 플로우]]
/// 가입 온보딩 1 — 이름 입력. 약관 동의 직후 진입.
/// 입력값은 delegate 로 코디네이터(AuthFeature)에 올린다 — 여기선 수집만 하고,
/// 제출은 `UserClient.updateProfile`(이름·직군·연차 일괄 PATCH) 배선 시점에 붙는다. TODO: 배선.
@Reducer
public struct AuthOnboardingNamingFeature {
    /// 이름 최대 길이 — PATCH /users/me/profile 계약(한글·영문만, 최대 5자).
    public static let maxLength = 5

    @ObservableState
    public struct State: Equatable {
        /// 프로그레스 바 분모 — 가입 온보딩 수집 단계 수(이름·직군·연차). 등록 완료 화면은 프로그레스 밖.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        public var name = ""

        public var isContinueEnabled: Bool {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && trimmed.count <= AuthOnboardingNamingFeature.maxLength
        }

        public init(step: Int = 1, totalSteps: Int = 3) {
            self.step = step
            self.totalSteps = totalSteps
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        @CasePathable
        public enum View: BindableAction, Sendable {
            case binding(BindingAction<State>)
            case userTappedContinue
            case userTappedClose
        }

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 이름 입력 완료 — 다음(직군 선택)으로.
            case continueRequested(name: String)
            /// 가입 온보딩 이탈(X) — 처리는 코디네이터 몫.
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        Reduce { state, action in
            switch action {
            case .view(.userTappedContinue):
                guard state.isContinueEnabled else { return .none }
                let trimmed = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return .send(.delegate(.continueRequested(name: trimmed)))

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case .view(.binding):
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
