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
        /// credential은 payload로만 흐른다 — State에 보관하지 않는다
        /// (백엔드 연동 시 signIn 내부에서 소비될 값이라 State에 두면 소비자 없는 죽은 데이터).
        case signInFinished(Result<SocialCredential, AuthError>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}

        // Delegate는 Action의 직접 멤버가 아니라 중첩 타입이라 @Reducer의
        // MemberAttributeMacro가 @CasePathable을 자동 부여하지 않는다(State/Action 이름의
        // 직속 멤버에만 적용됨) — store.receive(\.delegate.signedIn)을 쓰려면 명시가 필요하다.
        @CasePathable
        public enum Delegate: Equatable {
            /// 소셜 로그인 완료 — provider AT/RT 수신까지 성공.
            case signedIn
        }
    }

    @Dependency(\.authClient) var authClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .userTappedSignIn(provider):
                // 뷰의 .disabled는 재렌더 전 연속 탭을 막지 못한다 — 동시 로그인 플로우 2개가 뜨면
                // SDK 싱글턴의 completion 핸들러가 덮어써지므로 리듀서에서 확정적으로 차단한다.
                guard !state.isLoading else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let credential = try await authClient.signIn(provider)
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
            return "" // 도달 불가 — .cancelled는 얼럿 생성 전에 차단됨 (exhaustive switch 때문에만 존재)
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
