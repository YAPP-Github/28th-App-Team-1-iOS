//
//  AuthFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import DomainAuthInterface
import DomainConsentInterface

// @lat: [[auth#가입 플로우]]
// depends-on: [[app]] — 진입 판정(Splash 세션 복구)은 AppFeature 가 하고, 이 코디네이터는
//                       `State(resuming:)` 으로 그 결과를 받아 같은 게이트 체인에 합류한다.
/// 가입·로그인 플로우 코디네이터. AuthCreateAccount(소셜 로그인)를 루트로 두고,
/// 가입 경로(약관 동의 → 이름 → 직군 → 연차 → 등록 완료)를 `path`(StackState)로 push 한다.
/// 각 화면의 delegate 만 매칭해 수집 데이터를 누적하고 다음 화면으로 전환한다 — 조립은 여기서만(D5).
/// 플로우가 끝나면(가입 완료 or 기존 회원 로그인) `delegate(.signedIn)` 을 AppFeature 에 올린다.
///
/// **게이트 2단 체인** — 목적지는 두 값만으로 결정된다(docs/work/launch-routing.md):
/// ① 동의 게이트 `consentStatus` != `upToDate` → 약관 → ② 프로필 게이트 `profileRegistered` == false
/// → 온보딩(이름부터), 둘 다 통과면 곧장 `delegate(.signedIn)`. 로그인 경로와 세션 복구 경로가
/// 판정값 출처만 다르고 같은 체인을 탄다 — 분기 코드는 `enterGate` 한 곳뿐이다.
@Reducer
public struct AuthFeature {
    /// 가입 온보딩 수집 단계 수(이름·직군·연차) — 각 화면 프로그레스 바 분모. 등록 완료는 프로그레스 밖.
    /// TODO: 프로그레스 표기 여부·칸 수는 Figma 확정 시 조정.
    public static let onboardingSteps = 3

    @Reducer
    public enum Path {
        case terms(AuthTermsFeature)                       // A1 약관 동의(필수 5종)
        case naming(AuthOnboardingNamingFeature)           // 가입 온보딩 1 — 이름
        case job(AuthOnboardingJobFeature)                 // 가입 온보딩 2 — 직군
        case experience(AuthOnboardingExperienceFeature)   // 가입 온보딩 3 — 연차
        case register(AuthOnboardingRegisterFeature)       // 가입 온보딩 4 — 등록 완료(종결)
    }

    // @Reducer enum 이 생성하는 Path.State 는 Equatable 을 자동 채택하지 않는다 —
    // StackState<Path.State> 를 담는 코디네이터 State 의 Equatable 합성을 위해 명시한다.

    @ObservableState
    public struct State: Equatable {
        /// 루트 화면(A0 소셜 로그인).
        public var createAccount = AuthCreateAccountFeature.State()
        /// 가입 경로 네비게이션 스택.
        public var path = StackState<Path.State>()
        /// 프로필 게이트 판정값 — 약관을 통과한 뒤 온보딩/홈을 가른다. 판정 전에는 nil.
        /// 약관 화면을 거치는 동안 들고 있어야 해서 State 에 남는다(제출 응답엔 이 값이 없다).
        public var profileRegistered: Bool?
        /// 가입 온보딩 수집값 — 서버 제출 시점(화면별 즉시 vs 등록 완료 일괄)이 미결이라 코디네이터가 들고만 있다.
        public var name = ""
        public var jobRole: String?
        public var careerYears: Int?

        public init() {}

        /// 세션 복구 진입 — AppFeature 가 Splash 에서 이미 받은 판정값·약관 항목을 그대로 넘긴다.
        /// A0(소셜 로그인)를 거치지 않으므로 스택 첫 화면이 곧 목적지다(약관 또는 온보딩).
        /// 둘 다 통과한 경우는 AppFeature 가 홈으로 보내므로 여기까지 오지 않는다.
        public init(resuming destination: Destination) {
            switch destination {
            case let .terms(items, profileRegistered):
                self.profileRegistered = profileRegistered
                path.append(.terms(AuthTermsFeature.State(items: items)))
            case .onboarding:
                profileRegistered = false
                path.append(.naming(AuthOnboardingNamingFeature.State(
                    step: 1, totalSteps: AuthFeature.onboardingSteps
                )))
            }
        }
    }

    /// 세션 복구가 착지할 자리 — 게이트 2단 판정의 결과 중 «로그인 플로우가 이어받는» 둘.
    public enum Destination: Equatable, Sendable {
        /// 동의 게이트 미통과 — 조회해 둔 항목으로 약관 화면부터. 통과 후 프로필 게이트를 본다.
        case terms(items: [ConsentItem], profileRegistered: Bool)
        /// 동의는 끝났고 프로필만 없음 — 이름 입력부터.
        case onboarding
    }

    public enum Action {
        case createAccount(AuthCreateAccountFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 로그인 완료(기존 회원) 또는 가입 온보딩 완료 — 홈 진입 가능.
            case signedIn
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.createAccount, action: \.createAccount) {
            AuthCreateAccountFeature()
        }

        Reduce { state, action in
            switch action {
            // 소셜 인증 + 세션 교환 성공 — 게이트 2단 체인 진입.
            case let .createAccount(.delegate(.authenticated(result))):
                state.profileRegistered = result.profileRegistered
                return enterGate(&state, consentStatus: result.consentStatus)

            case .createAccount:
                return .none

            // A1 약관 동의 — 제출까지 화면이 마쳤다. 통과했으니 프로필 게이트로 넘긴다.
            // 이탈이면 A0 로 되돌린다(미제출 상태 유지 — 재진입 시 서버가 다시 약관으로 판정).
            case let .path(.element(id: _, action: .terms(.delegate(action)))):
                switch action {
                case .agreed:
                    return passProfileGate(&state)
                case .closeRequested:
                    state.path.removeAll()
                    return .none
                }

            // 가입 온보딩 1 이름 → 직군 push (이름은 직군 화면 타이틀에 주입).
            case let .path(.element(id: _, action: .naming(.delegate(action)))):
                switch action {
                case let .continueRequested(name):
                    state.name = name
                    state.path.append(.job(AuthOnboardingJobFeature.State(
                        userName: name, step: 2, totalSteps: Self.onboardingSteps
                    )))
                    return .none
                case .closeRequested:
                    // TODO: 가입 온보딩 중 X 의 의미(A0 복귀 vs 홈 직행) 미결 — 우선 A0 복귀.
                    state.path.removeAll()
                    return .none
                }

            // 가입 온보딩 2 직군 → 연차 push.
            case let .path(.element(id: _, action: .job(.delegate(action)))):
                switch action {
                case let .continueRequested(jobRole):
                    state.jobRole = jobRole
                    state.path.append(.experience(AuthOnboardingExperienceFeature.State(
                        step: 3, totalSteps: Self.onboardingSteps
                    )))
                    return .none
                case .closeRequested:
                    state.path.removeAll()
                    return .none
                }

            // 가입 온보딩 3 연차 → 등록 완료 push.
            case let .path(.element(id: _, action: .experience(.delegate(action)))):
                switch action {
                case let .continueRequested(careerYears):
                    state.careerYears = careerYears
                    state.path.append(.register(AuthOnboardingRegisterFeature.State(
                        userName: state.name
                    )))
                    return .none
                case .backRequested:
                    _ = state.path.popLast()
                    return .none
                case .closeRequested:
                    state.path.removeAll()
                    return .none
                }

            // 가입 온보딩 4 등록 완료 — 플로우 종료, AppFeature 에 홈 진입을 알린다.
            // TODO: 프로필 제출(이름·직군·연차) 일괄 확정 시 여기(또는 register 진입 시)에 effect 배선.
            case .path(.element(id: _, action: .register(.delegate(.completed)))):
                return .send(.delegate(.signedIn))

            case .path:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    // MARK: - 게이트 2단 체인

    /// 게이트 ① 동의 — 최신이면 곧장 프로필 게이트로, 아니면 약관 화면으로 보낸다.
    /// 약관 항목·버전은 로그인 응답에 없어 화면이 진입 시 `pending` 으로 직접 받는다(items: nil).
    private func enterGate(_ state: inout State, consentStatus: ConsentPendingStatus) -> Effect<Action> {
        guard consentStatus == .upToDate else {
            state.path.append(.terms(AuthTermsFeature.State()))
            return .none
        }
        return passProfileGate(&state)
    }

    /// 게이트 ② 프로필 — 등록됐으면 홈, 아니면 가입 온보딩(이름부터).
    /// 판정값이 없으면(계약 위반) 미등록으로 읽는다 — 온보딩을 한 번 더 보는 쪽이 안전한 실패다.
    private func passProfileGate(_ state: inout State) -> Effect<Action> {
        guard state.profileRegistered == true else {
            state.path.append(.naming(AuthOnboardingNamingFeature.State(
                step: 1, totalSteps: Self.onboardingSteps
            )))
            return .none
        }
        return .send(.delegate(.signedIn))
    }
}

// Path.State(=@Reducer enum 생성물)에 Equatable 합성 — 모든 화면 State 가 Equatable 이므로 성립.
extension AuthFeature.Path.State: Equatable {}
