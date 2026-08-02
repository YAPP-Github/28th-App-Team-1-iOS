//
//  AppFeature.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainAuthInterface
import DomainConsentInterface
import Feature

// @lat: [[app]]
// depends-on: [[auth]] — 로그인 전/후 루트 게이트. cross-feature 조립은 AppFeature 에서만.
// depends-on: [[home]] — Home 을 탭으로 임베드(owner). cross-feature delegate 라우팅은 Feature 추가 시 이 자리에서 조립.
// depends-on: [[onboarding]] — dev 전용 진입(Home 버튼)으로 온보딩 위저드를 present. 조립은 여기서만 (온보딩 본체 통합 전 임시).
@Reducer
struct AppFeature {
    /// 탭 식별자. 새 탭 추가 시: 여기 case → State 프로퍼티 → body Scope → AppView tabItem 순으로 확장.
    enum Tab: Hashable {
        case home
    }

    /// 루트가 지금 무엇을 띄우는가. Bool 조합으로는 «재시도 가능한 판정 실패» 를 표현할 수 없어 값으로 둔다.
    /// 전이는 Splash 판정(`onAppear`) → auth 또는 home 단방향이고, 로그아웃·세션 만료만 되돌린다.
    enum Root: Equatable {
        /// 세션 복구 판정 중 — SplashView.
        case splash
        /// 판정이 네트워크·서버 문제로 실패 — 토큰은 살아 있다. Splash 자리에서 재시도만 받는다.
        case splashFailed
        /// 로그인 전 또는 가입 플로우(약관·온보딩) 진행 중.
        case auth
        /// 두 게이트 모두 통과 — 탭 화면.
        case home
    }

    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        /// 루트가 무엇을 띄우는지 — 초기값은 Splash(판정 전).
        var root: Root = .splash
        var home = HomeFeature.State()
        var selectedTab: Tab = .home
        /// dev 전용 온보딩 위저드 — Home 진입 버튼으로 present (온보딩 본체 통합 전 임시).
        @Presents var onboarding: OnboardingFeature.State?
    }

    enum Action: BindableAction {
        case onAppear
        /// Splash 판정 실패 후 재시도.
        case retryLaunchRouting
        /// 세션 복구 판정 결과 — 목적지 또는 실패 종류.
        case launchRoutingResolved(LaunchRouting)
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        /// 로그아웃 정리(서버·토큰·draft) 완료 — 초기 State 로 리셋해 로그인 화면으로 돌아간다.
        case sessionCleared
        case binding(BindingAction<State>)
    }

    /// Splash 판정의 결과. 게이트 2단 체인의 목적지 + 두 실패 종류다 (docs/work/launch-routing.md).
    enum LaunchRouting: Equatable, Sendable {
        /// 토큰 없음 또는 refresh 가 만료로 거부됨(토큰 폐기 완료) — 소셜 로그인부터.
        case login
        /// 게이트 미통과 — 가입 플로우가 이어받는다(약관 또는 온보딩).
        case resume(AuthFeature.Destination)
        /// 두 게이트 통과 — 홈 직행.
        case home
        /// 판정 불가(네트워크·5xx·계약 불일치) — 토큰은 유지된다. 재시도 대상.
        ///
        /// 도메인 에러 매핑이 원인을 `unexpected` 하나로 뭉개므로 **어느 단계에서 무엇으로** 실패했는지를
        /// 함께 싣는다 — 이게 없으면 스플래시에 갇혔을 때 refresh 인지 pending 인지조차 알 수 없다.
        /// 에러를 그대로 싣지 않고 설명 문자열로 옮기는 건 `any Error` 가 Sendable 이 아니라서다.
        case failed(step: String, reason: String)
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.consentClient) var consentClient
    @Dependency(\.onboardingDraftStore) var draftStore

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                // dev 계에서만 Home 온보딩 진입·디버그 로그아웃 버튼을 노출한다.
                state.home.showsOnboardingEntry = AppEnvironment.isDev
                state.home.showsDebugLogout = AppEnvironment.isDev
                return resolveLaunchRouting()

            case .retryLaunchRouting:
                state.root = .splash
                return resolveLaunchRouting()

            case let .launchRoutingResolved(routing):
                return apply(routing, to: &state)

            case let .auth(.delegate(.signedIn)):
                // 새 로그인 = 새 세션. 이전 사용자가 하던 화면·데이터를 전부 버리고 초기 State 에서 시작한다.
                state = State()
                state.root = .home
                state.home.showsOnboardingEntry = AppEnvironment.isDev
                state.home.showsDebugLogout = AppEnvironment.isDev
                return .none
            case .auth:
                return .none
            case .home(.delegate(.onboardingRequested)):
                state.onboarding = OnboardingFeature.State()
                return .none
            case .home(.delegate(.interviewStartRequested)):
                // TODO: 면접 플로우 조립 — 게이트(checkStartEligibility) 결과별 라우팅(위저드 cover / S2 강제 /
                //       AuthSuspension). `FeatureInterview` 는 아직 App 에 scope 조차 없다
                //       (docs/work/home-account.md §4, 미결 6-1 서버 협의).
                return .none
            case .home(.delegate(.interviewInfoEditRequested)):
                // TODO: 면접 정보 수정(직군·연차·JD·포폴) 진입 조립 — 소유 Feature 확정 후.
                return .none
            case .home(.delegate(.profileRequested)):
                // TODO: 마이페이지 진입 — Part 5 Feature 가 생기면 조립한다(docs/work/home-account.md §4).
                return .none
            case .home(.delegate(.reportDetailRequested)):
                // TODO: 리포트 상세(r1/최종) 제시 — `InterviewReportFeature` 통합 후 sessionId 로 배선.
                return .none
            case .home(.delegate(.logoutRequested)):
                // 서버 로그아웃(+토큰 Keychain 삭제)·온보딩 draft(UserDefaults) 삭제. 실패해도 로컬 정리는 진행.
                return .run { send in
                    try? await authClient.logout()
                    draftStore.clear()
                    await send(.sessionCleared)
                }
            case .home:
                return .none
            // 온보딩 완료(분석까지)/중도 이탈 모두 위저드를 닫는다. finished(sessionId:) 는
            // 본체 통합 시 Part2 진입에 쓰지만 dev 진입에선 닫기만 한다.
            case .onboarding(.presented(.delegate(.finished))),
                 .onboarding(.presented(.delegate(.dismiss))):
                state.onboarding = nil
                return .none
            case .onboarding:
                return .none
            case .sessionCleared:
                // 로그아웃 정리 완료 — 초기 State 로 리셋하고 첫 소셜 로그인 화면으로.
                // Splash 로 되돌리지 않는다 — 로그아웃 복귀는 판정이 아니라 확정 상태다.
                state = State()
                state.root = .auth
                state.home.showsOnboardingEntry = AppEnvironment.isDev
                state.home.showsDebugLogout = AppEnvironment.isDev
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }

    // MARK: - Splash 세션 복구 판정 → [[auth#가입 플로우]]

    /// 토큰 유무 → pending 한 콜로 목적지를 정한다 (docs/work/launch-routing.md §4).
    ///
    /// refresh 를 **먼저 때리지 않는다** — Access 는 3시간이라 콜드 스타트 대부분 살아 있고,
    /// 만료면 이 호출의 403 을 AuthorizedNetworkClient 가 잡아 재발급 후 재시도한다([[api#토큰 수명주기]]).
    /// 매 실행 무조건 rotation 은 콜 낭비 + 페어 교체 중 앱 킬 = 세션 유실 리스크만 키운다.
    ///
    /// 실패는 **두 종류로 갈라야** 한다 — `sessionExpired`(재발급까지 실패, 토큰은 인터셉터가 이미 폐기)는
    /// 재로그인이고, 네트워크·5xx 는 판정 불가라 토큰을 살려 둔 채 재시도한다.
    /// 뭉뚱그리면 오프라인에서 앱을 켠 사용자가 로그아웃당한다.
    private func resolveLaunchRouting() -> Effect<Action> {
        .run { send in
            guard authClient.isAuthenticated() else {
                return await send(.launchRoutingResolved(.login))
            }
            do {
                // 게이트 판정값 2개를 한 번에 받는다 — 약관 항목까지 딸려와 재조회가 없고,
                // 인증 필요 API 라 세션 유효성 검증을 겸한다.
                let pending = try await consentClient.pending()
                await send(.launchRoutingResolved(routing(for: pending)))
            } catch ConsentError.sessionExpired {
                await send(.launchRoutingResolved(.login))
            } catch {
                await send(.launchRoutingResolved(.failed(step: "consents/pending", reason: "\(error)")))
            }
        }
    }

    /// 게이트 2단 체인 — ① 동의(`status`) ② 프로필(`profileRegistered`). 순서가 고정이다.
    private func routing(for pending: ConsentPending) -> LaunchRouting {
        guard pending.status == .upToDate else {
            return .resume(.terms(items: pending.items, profileRegistered: pending.profileRegistered))
        }
        return pending.profileRegistered ? .home : .resume(.onboarding)
    }

    private func apply(_ routing: LaunchRouting, to state: inout State) -> Effect<Action> {
        switch routing {
        case .login:
            state.auth = AuthFeature.State()
            state.root = .auth
        case let .resume(destination):
            state.auth = AuthFeature.State(resuming: destination)
            state.root = .auth
        case .home:
            state.root = .home
        case let .failed(step, reason):
            #if DEBUG
            print("🚧 [LAUNCH-ROUTING] \(step) 실패 — \(reason)")
            #endif
            state.root = .splashFailed
        }
        return .none
    }
}
