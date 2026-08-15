//
//  AuthCreateAccountFeature.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import DomainCommonInterface

// @lat: [[auth]]
/// AuthCreateAccount(A0) — 가입·로그인 단일 진입점. 소셜 인증(signIn) + 서버 세션 교환(login)까지 마치고
/// 코디네이터(AuthFeature)에 `delegate(.authenticated)` 를 올린다. 신규/기존 분기는 코디네이터 몫.
///
/// 스토어 심사용 코드 로그인도 이 화면에 얹혀 있다 — 소셜 경로와 **같은 inner·delegate 를 탄다**
/// (교환 함수만 다르다). → [[auth#심사용 코드 로그인]]
@Reducer
public struct AuthCreateAccountFeature {
    /// 심사용 코드 입력을 여는 로고 탭 횟수.
    public static let reviewCodeTapThreshold = 5

    /// 로그인 성공 payload — 라우팅 판정값과, 애플이 준 이름을 함께 나른다.
    /// 연관값 둘을 늘어놓지 않고 한 값으로 묶는 건 case path 를 살리기 위해서다
    /// (연관값 2개짜리 case 는 튜플이라 `\.inner.signInFinished.success` 로 파고들 수 없다).
    public struct SignInSuccess: Equatable, Sendable {
        public let result: LoginResult
        /// 애플이 **최초 인가 1회에만** 주는 이름 — 카카오·재로그인·심사용 코드 경로는 nil.
        public let socialName: String?

        public init(result: LoginResult, socialName: String? = nil) {
            self.result = result
            self.socialName = socialName
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 인증 진행 중 — **표시용이 아니라 재탭 차단용**이다. 로딩 표시는 AppView 의 전역
        /// LoadingModal(NetworkActivity) 몫이지만, 그건 HTTP in-flight 만 센다. 소셜 SDK 구간
        /// (`authClient.signIn`)은 네트워크 계측 밖이라 이 플래그가 없으면 시트가 뜨기 전 두 번 눌린다.
        public var isAuthenticating = false
        /// 로고 탭 누적 — 심사용 코드 입력을 여는 카운터. 임계치에 닿으면 더 세지 않는다.
        public var logoTapCount = 0
        public var reviewCode = ""
        @Presents public var alert: AlertState<Action.Alert>?

        /// 심사용 코드 입력 노출 여부. 일반 사용자는 로고를 5번 두드릴 일이 없어 평소엔 닫혀 있다 —
        /// 숨긴 상대는 사용자가 아니라 화면이고, 경로 자체는 App Review 노트에 적어 공개한다.
        public var showsReviewCodeField: Bool {
            logoTapCount >= AuthCreateAccountFeature.reviewCodeTapThreshold
        }

        /// 빈 코드로 서버를 때리지 않는다 — 앞뒤 공백만 있는 입력도 막는다.
        public var isReviewCodeSubmittable: Bool {
            !reviewCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        @CasePathable
        public enum View: BindableAction, Sendable {
            case binding(BindingAction<State>)
            /// 로고 탭 — 임계치까지 세어 심사용 코드 입력을 연다.
            case userTappedLogo
            /// 심사용 코드 제출 — 소셜 경로와 같은 inner 로 합류한다.
            case userTappedReviewCodeSignIn
            case userTappedSignIn(SocialProvider)
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Sendable {
            /// signIn(자격증명 획득) → login(서버 세션 교환·토큰 저장)까지 마친 결과.
            /// credential 자체는 같은 effect 안에서 login 에 소비되고 남기지 않는다 — 이후 분기에
            /// 필요한 건 `SignInSuccess`(판정값 + 애플이 준 이름)뿐이다. 이름을 여기서 흘리면
            /// 다시 얻을 길이 없다 — 애플은 최초 인가에만 주고 재로그인은 nil 로 온다.
            case signInFinished(Result<SignInSuccess, AuthError>)
        }

        public enum Alert: Equatable {}

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable {
            /// 소셜 인증 + 서버 세션 교환(토큰 Keychain 저장) 성공.
            /// 게이트 2단(동의 → 프로필) 분기는 판정값을 받은 코디네이터가 한다.
            case authenticated(SignInSuccess)
        }
    }

    @Dependency(\.authClient) var authClient

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        Reduce { state, action in
            switch action {
            case .view(.userTappedLogo):
                // 열린 뒤로는 셀 필요가 없다 — 카운터를 계속 올리면 Int 만 자란다.
                guard !state.showsReviewCodeField else { return .none }
                state.logoTapCount += 1
                return .none

            // 심사용 코드 교환 — signIn(소셜 SDK) 단계가 없어 서버 교환 한 번이 전부다.
            // 성공·실패 처리는 아래 소셜 경로와 공유한다(같은 inner).
            case .view(.userTappedReviewCodeSignIn):
                guard !state.isAuthenticating, state.isReviewCodeSubmittable else { return .none }
                state.isAuthenticating = true
                let code = state.reviewCode.trimmingCharacters(in: .whitespacesAndNewlines)
                return .run { send in
                    do {
                        let result = try await authClient.loginWithReviewCode(code)
                        // 소셜 SDK 를 거치지 않는 경로라 실어 올 이름이 없다 — 이름 화면은 그대로 뜬다.
                        await send(.inner(.signInFinished(.success(.init(result: result)))))
                    } catch {
                        await send(.inner(.signInFinished(.failure(error as? AuthError ?? .unexpected))))
                    }
                }

            case let .view(.userTappedSignIn(provider)):
                guard !state.isAuthenticating else { return .none }
                state.isAuthenticating = true
                return .run { send in
                    do {
                        let credential = try await authClient.signIn(provider)
                        // 서버 세션 교환 — 성공 시 토큰 페어가 Keychain(TokenStore)에 저장된다.
                        // 이게 없으면 인증 필요 API 가 전부 NotAuthenticatedError 로 끊긴다.
                        let result = try await authClient.login(credential)
                        await send(.inner(.signInFinished(.success(
                            .init(result: result, socialName: credential.socialName)
                        ))))
                    } catch {
                        await send(.inner(.signInFinished(.failure(error as? AuthError ?? .unexpected))))
                    }
                }

            // 코드 입력 바인딩 — 반영은 BindingReducer 가 이미 했다.
            case .view(.binding):
                return .none

            case let .inner(.signInFinished(.success(success))):
                state.isAuthenticating = false
                return .send(.delegate(.authenticated(success)))

            case .inner(.signInFinished(.failure(.cancelled))):
                state.isAuthenticating = false
                return .none

            case let .inner(.signInFinished(.failure(error))):
                state.isAuthenticating = false
                // TODO: PRD Part7 A0 — alert 가 아니라 토스트("로그인에 실패했어요. 다시 시도해주세요")로 교체.
                // 미승격 서버 에러는 공통 Alert 로 — title «CODE(status)», message 원문.
                if let serverAlert: AlertState<Action.Alert> = error.serverAlertState() {
                    state.alert = serverAlert
                } else {
                    state.alert = AlertState(
                        title: { TextState(error.alertMessage) },
                        actions: {
                            ButtonState(role: .cancel) {
                                TextState("확인")
                            }
                        }
                    )
                }
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
        case .server:
            // 도달 안 함 — serverAlert 분기가 먼저 잡는다. exhaustive switch 충족용.
            return "알 수 없는 오류가 발생했습니다."
        case .unexpected:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
