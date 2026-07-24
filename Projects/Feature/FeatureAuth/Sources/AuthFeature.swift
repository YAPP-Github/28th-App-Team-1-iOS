//
//  AuthFeature.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface

// @lat: [[auth]]
@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action {
        case userTappedSignIn(SocialProvider)
        /// signIn(자격증명 획득) → login(서버 세션 교환·토큰 저장)까지 마친 결과.
        /// credential 은 같은 effect 안에서 login 에 즉시 소비되고, payload 로만 흐른다 — State 에 보관하지 않는다.
        case signInFinished(Result<SocialCredential, AuthError>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}

        @CasePathable
        public enum Delegate: Equatable {
            /// 로그인 완료 — 서버 세션 교환(토큰 Keychain 저장)까지 성공. 이후 인증 필요 API 호출 가능.
            case signedIn
        }
    }

    @Dependency(\.authClient) var authClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .userTappedSignIn(provider):
                guard !state.isLoading else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let credential = try await authClient.signIn(provider)
                        // 서버 세션 교환 — 성공 시 토큰 페어가 Keychain(TokenStore)에 저장된다.
                        // 이게 없으면 인증 필요 API 가 전부 NotAuthenticatedError 로 끊긴다.
                        try await authClient.login(credential)
                        await send(.signInFinished(.success(credential)))
                    } catch {
                        await send(.signInFinished(.failure(error as? AuthError ?? .unexpected)))
                    }
                }

            case .signInFinished(.success):
                state.isLoading = false
                return .send(.delegate(.signedIn))

            case .signInFinished(.failure(.cancelled)):
                state.isLoading = false
                return .none

            case let .signInFinished(.failure(error)):
                state.isLoading = false
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
