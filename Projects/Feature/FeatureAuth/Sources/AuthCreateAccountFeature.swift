//
//  AuthCreateAccountFeature.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface

// @lat: [[auth]]
/// AuthCreateAccount(A0) — 가입·로그인 단일 진입점. 소셜 인증(signIn) + 서버 세션 교환(login)까지 마치고
/// 코디네이터(AuthFeature)에 `delegate(.authenticated)` 를 올린다. 신규/기존 분기는 코디네이터 몫.
@Reducer
public struct AuthCreateAccountFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case userTappedSignIn(SocialProvider)
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Sendable {
            /// signIn(자격증명 획득) → login(서버 세션 교환·토큰 저장)까지 마친 결과.
            /// credential 은 같은 effect 안에서 login 에 즉시 소비되고, payload 로만 흐른다 — State 에 보관하지 않는다.
            case signInFinished(Result<SocialCredential, AuthError>)
        }

        public enum Alert: Equatable {}

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable {
            /// 소셜 인증 + 서버 세션 교환(토큰 Keychain 저장) 성공. 신규/기존·동의 버전 분기는 코디네이터가 한다.
            case authenticated
        }
    }

    @Dependency(\.authClient) var authClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.userTappedSignIn(provider)):
                guard !state.isLoading else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let credential = try await authClient.signIn(provider)
                        // 서버 세션 교환 — 성공 시 토큰 페어가 Keychain(TokenStore)에 저장된다.
                        // 이게 없으면 인증 필요 API 가 전부 NotAuthenticatedError 로 끊긴다.
                        try await authClient.login(credential)
                        await send(.inner(.signInFinished(.success(credential))))
                    } catch {
                        await send(.inner(.signInFinished(.failure(error as? AuthError ?? .unexpected))))
                    }
                }

            case .inner(.signInFinished(.success)):
                state.isLoading = false
                return .send(.delegate(.authenticated))

            case .inner(.signInFinished(.failure(.cancelled))):
                state.isLoading = false
                return .none

            case let .inner(.signInFinished(.failure(error))):
                state.isLoading = false
                // TODO: PRD Part7 A0 — alert 가 아니라 토스트("로그인에 실패했어요. 다시 시도해주세요")로 교체.
                state.alert = AlertState(
                    title: { TextState(error.alertMessage) },
                    actions: {
                        ButtonState(role: .cancel) {
                            TextState("확인")
                        }
                    }
                )
                return .none

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private extension AuthError {
    var alertMessage: String {
        switch self {
        case .cancelled:
            return ""
        case .networkFailure:
            return "네트워크 연결을 확인해주세요."
        case .invalidCredential:
            return "로그인 정보가 올바르지 않습니다."
        case .serverUnavailable:
            return "서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해주세요."
        case .sessionExpired:
            return "로그인이 만료되었습니다. 다시 로그인해주세요."
        case .unexpected:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
