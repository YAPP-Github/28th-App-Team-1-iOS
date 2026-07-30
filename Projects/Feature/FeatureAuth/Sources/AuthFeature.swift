//
//  AuthFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

// @lat: [[auth#가입 플로우]]
/// 가입·로그인 플로우 코디네이터. AuthCreateAccount(소셜 로그인)를 루트로 두고,
/// 신규 가입 경로(약관 동의 → 이름 → 직군 → 연차 → 등록 완료)를 `path`(StackState)로 push 한다.
/// 각 화면의 delegate 만 매칭해 수집 데이터를 누적하고 다음 화면으로 전환한다 — 조립은 여기서만(D5).
/// 플로우가 끝나면(가입 완료 or 기존 회원 로그인) `delegate(.signedIn)` 을 AppFeature 에 올린다.
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
        /// 가입 온보딩 수집값 — 서버 제출 시점(화면별 즉시 vs 등록 완료 일괄)이 미결이라 코디네이터가 들고만 있다.
        public var name = ""
        public var jobRole: String?
        public var careerYears: Int?

        public init() {}
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
            // 소셜 인증 + 세션 교환 성공 — 신규/기존·동의 버전 분기 지점.
            // TODO(S-1): login 응답에 신규/기존·동의 버전 판별이 아직 없어 전원 신규로 취급해 약관으로 보낸다.
            //   서버 계약 확정 시: 기존+최신 → 바로 delegate(.signedIn) / 기존+구버전 → 재동의(A3, MVP 자리만).
            case .createAccount(.delegate(.authenticated)):
                state.path.append(.terms(AuthTermsFeature.State()))
                return .none

            case .createAccount:
                return .none

            // A1 약관 동의 — 완료면 가입 온보딩(이름)으로, 이탈이면 A0 로 되돌린다(계정 미생성 — 서버 판정).
            case let .path(.element(id: _, action: .terms(.delegate(action)))):
                switch action {
                case .agreed:
                    // TODO(S-1): 동의 제출 API(계정 생성 확정 + 무료 3회 부여 + 이력 저장) effect 가 여기 붙는다.
                    state.path.append(.naming(AuthOnboardingNamingFeature.State(
                        step: 1, totalSteps: Self.onboardingSteps
                    )))
                    return .none
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
}

// Path.State(=@Reducer enum 생성물)에 Equatable 합성 — 모든 화면 State 가 Equatable 이므로 성립.
extension AuthFeature.Path.State: Equatable {}
