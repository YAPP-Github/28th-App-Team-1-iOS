//
//  AuthOnboardingRegisterFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

// @lat: [[auth#가입 플로우]]
/// 가입 온보딩 4 — 등록 완료. 수집(이름·직군·연차)이 끝났음을 알리고 홈 진입으로 잇는 종결 화면(프로그레스 밖).
/// TODO: 프로필 제출(이름·직군·연차) 시점이 «각 화면 즉시 vs 여기 일괄»로 미결 — 일괄로 확정되면
/// 이 화면 진입 시 `UserClient.registerName`·`updateProfile` effect 가 붙는다.
@Reducer
public struct AuthOnboardingRegisterFeature {
    @ObservableState
    public struct State: Equatable {
        /// 코디네이터가 주입하는 사용자 이름. 확정 시안(node 3632:14643)의 완료 문구는 이름을
        /// 끼우지 않아 화면에 안 쓰이지만, 프로필 일괄 제출(아래 TODO)이 여기로 오면 필요해 남긴다.
        public var userName: String

        public init(userName: String = "") {
            self.userName = userName
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case userTappedStart
        }

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 가입 온보딩 완료 — 코디네이터가 delegate(.signedIn)으로 홈 진입을 알린다.
            case completed
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.userTappedStart):
                return .send(.delegate(.completed))

            case .delegate:
                return .none
            }
        }
    }
}
