//
//  AppFeature.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import CoreCommonInterface
import DomainAppVersionInterface
import DomainAuthInterface
import DomainConsentInterface
import Feature
import Foundation

// @lat: [[app]]
// depends-on: [[auth]] — 로그인 전/후 루트 게이트. cross-feature 조립은 AppFeature 에서만.
// depends-on: [[home]] — Home 을 탭으로 임베드(owner). cross-feature delegate 라우팅은 Feature 추가 시 이 자리에서 조립.
// depends-on: [[interview]] — 온보딩이 만든 세션(finished(sessionId:))으로 면접 cover 를 present. 조립은 여기서만.
// depends-on: [[onboarding]] — 「면접 시작」의 [시작하기]·[수정하기] 가 온보딩 위저드를 present. 조립은 여기서만.
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
        /// 강제 업데이트(FORCE) — 세션 판정 자체를 하지 않고 진입을 막는다. 재시도로 빠져나올 수 없다.
        case updateRequired
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
        /// 면접 흐름(Part 2) — 온보딩이 세션을 만들어 준 뒤에만 열린다(`finished(sessionId:)`).
        /// 세션 없이 진입할 길이 없어 `sessionId` 를 들고 시작한다.
        @Presents var interview: InterviewFeature.State?
        /// dev 전용 온보딩 위저드 — Home 진입 버튼으로 present (온보딩 본체 통합 전 임시).
        @Presents var onboarding: OnboardingFeature.State?
        /// 업데이트 안내(강제·권장)의 근거 — «업데이트» 가 열 `storeUrl` 과 강제 여부를 여기서 읽는다.
        var updatePolicy: AppVersionPolicy?
        @Presents var updateAlert: AlertState<Action.UpdateAlert>?
    }

    enum Action: BindableAction {
        case onAppear
        /// 첫 실행 정리가 끝났다 — 이제 세션 복구 판정을 시작해도 된다.
        case firstLaunchResolved
        /// Splash 판정 실패 후 재시도.
        case retryLaunchRouting
        /// 버전 게이트 판정 결과 — 안내가 필요한 FORCE·OPTIONAL 만 도달한다.
        case appVersionResolved(AppVersionPolicy)
        /// 강제 업데이트에서 스토어를 다녀온 뒤 — 차단을 유지하려 같은 알럿을 다시 세운다.
        case updateAlertReasserted
        case updateAlert(PresentationAction<UpdateAlert>)
        /// 세션 복구 판정 결과 — 목적지 또는 실패 종류.
        case launchRoutingResolved(LaunchRouting)
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
        case interview(PresentationAction<InterviewFeature.Action>)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        /// 로그아웃 정리(서버·토큰·draft) 완료 — 초기 State 로 리셋해 로그인 화면으로 돌아간다.
        case sessionCleared
        case binding(BindingAction<State>)

        /// 업데이트 알럿 버튼. 강제(FORCE)일 땐 «나중에» 를 만들지 않아 도달하지 않는다.
        @CasePathable
        enum UpdateAlert: Equatable, Sendable {
            case userTappedUpdate
            case userTappedLater
        }
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

    @Dependency(\.appVersionClient) var appVersionClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.consentClient) var consentClient
    @Dependency(\.firstLaunchStore) var firstLaunchStore
    @Dependency(\.onboardingDraftStore) var draftStore
    @Dependency(\.openURL) var openURL

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
                // 잔존 정리를 **판정보다 먼저** 끝낸다 — 순서를 지키려 판정을 effect 안에서 잇지 않고
                // 별도 액션으로 갈라 놓는다.
                return .run { send in
                    clearIfFirstLaunch()
                    await send(.firstLaunchResolved)
                }

            case .firstLaunchResolved:
                return resolveLaunchRouting()

            case .retryLaunchRouting:
                state.root = .splash
                return resolveLaunchRouting()

            case let .appVersionResolved(policy):
                state.updatePolicy = policy
                let isForced = policy.updateType == .force
                // FORCE 는 세션 판정 자체가 멈춘 상태다 — 루트를 옮겨 Splash 에 갇힌 것과 구분한다.
                if isForced { state.root = .updateRequired }
                state.updateAlert = .update(isForced: isForced)
                return .none

            case .updateAlert(.presented(.userTappedUpdate)):
                guard let policy = state.updatePolicy else { return .none }
                let isForced = policy.updateType == .force
                return .run { send in
                    if let url = URL(string: policy.storeUrl) { await openURL(url) }
                    // 스토어에서 그냥 돌아와도 강제 업데이트는 계속 막는다.
                    if isForced { await send(.updateAlertReasserted) }
                }

            case .updateAlertReasserted:
                state.updateAlert = .update(isForced: true)
                return .none

            case .updateAlert:
                return .none

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
                state.onboarding = OnboardingFeature.State(userName: state.home.userName)
                return .none
            case .home(.delegate(.interviewStartRequested)):
                // 면접에 필요한 정보(직군·연차·JD·포폴)를 모으는 게 온보딩 위저드다 — 첫 면접은 거기부터다.
                // 면접 화면은 **세션 id 로만** 열리는데(`InterviewFeature.State(sessionId:)`) 그 id 를 만드는
                // 건 위저드의 세션 생성뿐이라, 재사용 경로도 지금은 같은 위저드를 태운다.
                switch state.home.startInterview.variant {
                case .first:
                    state.onboarding = OnboardingFeature.State(userName: state.home.userName)
                case .hasPortfolio:
                    // TODO: «이전 정보 그대로» 세션 생성 API 가 생기면 수집을 건너뛰고 곧장 면접으로
                    //       (게이트 checkStartEligibility 결과별 라우팅 — 미결 6-1 서버 협의).
                    //       그때까지는 위저드를 태운다 — draft 가 값을 복원해 대부분 넘기기만 하면 되고,
                    //       아무 일도 안 일어나는 [시작하기] 보다는 낫다.
                    state.onboarding = OnboardingFeature.State(userName: state.home.userName)
                case .exhausted:
                    // 소진 시안엔 [시작하기] 가 없다(CTA 는 «홈으로») — 도달하지 않는다.
                    break
                }
                return .none
            case .home(.delegate(.interviewInfoEditRequested)):
                // [수정하기] — 고칠 대상이 온보딩이 모으는 그 정보다. 같은 위저드를 처음부터 다시 태운다.
                // 저장된 draft 가 살아 있으면 위저드가 알아서 값을 복원한다(TTL 14일 — [[onboarding#코디네이터]]).
                state.onboarding = OnboardingFeature.State(userName: state.home.userName)
                return .none
            case .home(.delegate(.profileRequested)):
                // TODO: 마이페이지 진입 — Part 5 Feature 가 생기면 조립한다(docs/work/home-account.md §4).
                return .none
            case .home(.delegate(.reportDetailRequested)):
                // TODO: 리포트 상세(r1/최종) 제시 — `InterviewReportFeature` 통합 후 sessionId 로 배선.
                return .none
            case .home(.delegate(.logoutRequested)):
                // 서버 로그아웃 후 로컬 정리. 서버 호출이 실패해도 로컬은 그대로 지운다.
                return .run { send in
                    try? await authClient.logout()
                    clearLocalData()
                    await send(.sessionCleared)
                }
            case .home:
                return .none
            // 온보딩 완료 = **세션이 준비됐다** — 위저드를 닫고 그 자리에서 면접으로 넘긴다.
            // 홈을 태우지 않는 이유: 지금 홈은 면접 뒤에 가려질 뿐이고, 갱신이 필요한 시점은
            // 면접이 끝나 홈으로 돌아올 때다(아래 `interview` delegate 두 갈래가 태운다).
            case let .onboarding(.presented(.delegate(.finished(sessionId)))):
                state.onboarding = nil
                state.interview = InterviewFeature.State(sessionId: sessionId)
                return .none
            // 중도 이탈 — 위저드만 닫고 홈을 다시 태운다. STEP4 에서 업로드는 이미 끝났을 수 있어
            // 안 태우면 «이전 정보 재사용» 카드가 옛 값 그대로 남는다. cover 를 닫는 것만으론 홈의
            // `onAppear` 가 다시 오지 않아 여기서 명시로 보낸다(겸사겸사 시트도 기본 자리로 —
            // 위저드를 다녀온 뒤 면접 시작 겹에 그대로 서 있지 않는다).
            case .onboarding(.presented(.delegate(.dismiss))):
                state.onboarding = nil
                return .send(.home(.view(.onAppear)))
            case .onboarding:
                return .none
            // 면접 종료·이탈 모두 cover 를 닫고 홈을 다시 태운다 — 어느 쪽이든 잔여가 줄었고,
            // 정상 종료면 리포트도 늘었다.
            // TODO: 정상 종료는 리포트 상세(r1)로 이어져야 한다 — `InterviewReportFeature` 통합 후
            //       sessionId 로 배선 (docs/work/home-account.md §4).
            case .interview(.presented(.delegate(.finished))),
                 .interview(.presented(.delegate(.closed))):
                state.interview = nil
                return .send(.home(.view(.onAppear)))
            case .interview:
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
        .ifLet(\.$interview, action: \.interview) {
            InterviewFeature()
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifLet(\.$updateAlert, action: \.updateAlert)
    }

    // MARK: - 첫 실행 정리 → [[app#첫 실행 정리]]

    /// 이 설치의 첫 실행이면 잔존 로컬 데이터를 지운다 — 앱을 지워도 Keychain 은 남기 때문이다.
    ///
    /// 남는 게 토큰뿐이라 정리를 안 하면 재설치 직후가 «로그인된 상태» 로 판정된다. 삭제와 함께
    /// 사라지는 UserDefaults 쪽(draft)은 이미 비어 있어 지워도 손해가 없다 — 판정 하나로 둘 다 맞춘다.
    ///
    /// 마커는 **정리 뒤에** 찍는다. 사이에서 앱이 죽으면 다음 실행이 다시 첫 실행으로 판정돼 정리를
    /// 마치는데, 먼저 찍으면 지우다 만 상태로 굳는다.
    private func clearIfFirstLaunch() {
        guard firstLaunchStore.isFirstLaunch() else { return }
        clearLocalData()
        firstLaunchStore.markLaunched()
    }

    /// 로컬 저장소 정리 — 첫 실행 정리와 로그아웃이 공유한다. 서버 호출은 하지 않는다.
    ///
    /// Keychain 은 `tokenStore.clear()`(항목 하나)가 아니라 **전체**를 지운다 — 목적이 «앱이 남긴 것
    /// 전부» 라 Keychain 항목이 늘어도 놓치지 않아야 한다. UserDefaults 는 도메인째 지우지 않는다:
    /// 첫 실행 마커가 거기 있어 통째로 날리면 다음 실행이 다시 첫 실행으로 판정된다.
    private func clearLocalData() {
        KeychainWipe.wipeAll()
        draftStore.clear()
    }

    // MARK: - Splash 세션 복구 판정 → [[auth#가입 플로우]]

    /// 버전 게이트 → 토큰 유무 → pending 한 콜로 목적지를 정한다 (docs/work/launch-routing.md §4).
    ///
    /// 버전 게이트가 **먼저**다 — FORCE 인데 뒤에 두면 이미 홈에 들어간 뒤에 막게 된다. 무인증 API 라
    /// 토큰 유무와 무관하게 돌릴 수 있다. 실패는 **fail-open** — 버전 정책 서버가 죽었다고 앱 실행까지
    /// 막지 않는다([[api#AppVersion]]).
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
            if let policy = await checkAppVersion(), policy.updateType != .none {
                await send(.appVersionResolved(policy))
                // FORCE 는 여기서 끝 — 세션 판정을 시작하지 않는다.
                if policy.updateType == .force { return }
            }
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

    /// 버전 판정 — 실패(네트워크·5xx·버전 키 없음)는 nil 로 삼켜 진입을 막지 않는다(fail-open).
    private func checkAppVersion() async -> AppVersionPolicy? {
        guard let version = AppEnvironment.marketingVersion else { return nil }
        return try? await appVersionClient.check(version)
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

// MARK: - 업데이트 안내

// TODO: 시안 수령 시 OS 기본 Alert → 전용 화면/시트로 교체. 문구도 그때 확정한다.
private extension AlertState where Action == AppFeature.Action.UpdateAlert {
    /// 강제면 «나중에» 를 만들지 않는다 — 버튼이 하나뿐이라 알럿을 닫고 앱을 쓸 길이 없다.
    static func update(isForced: Bool) -> Self {
        AlertState {
            TextState(isForced ? "업데이트가 필요해요" : "새 버전이 나왔어요")
        } actions: {
            ButtonState(action: .userTappedUpdate) { TextState("업데이트") }
            if !isForced {
                ButtonState(role: .cancel, action: .userTappedLater) { TextState("나중에") }
            }
        } message: {
            TextState(
                isForced
                    ? "계속 사용하려면 최신 버전으로 업데이트해주세요."
                    : "더 편해진 기능을 쓰려면 업데이트해주세요."
            )
        }
    }
}
