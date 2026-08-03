# App 도메인 — 코디네이터 (AppFeature)

앱 최상위 Reducer 겸 **탭 코디네이터**. 각 탭 Feature 의 State 를 보유하고, **Feature 간(cross-feature) 전환은 여기서만** 조립한다. 각 Feature 는 서로를 모르고 `delegate` 로만 신호를 올린다. (현재 #6 은 스켈레톤 — AppFeature 는 골격이고 탭은 이관되며 채워진다.)

## 탭 구성
`Scope` 로 각 Feature 를 상시 임베드한다. App 은 `.feature` umbrella 를 link 하므로 자식 reducer 를 구체 타입으로 안다. 탭끼리는 서로를 모른다.
- 예정 탭 여럿 중 현재 실 Feature 는 Home 뿐. → [[home]]
- 각 Feature 의 **도메인 내부** navigation 은 그 Feature 가 자체 처리(`Path`/`StackState`). AppFeature 는 관여하지 않는다.

## Cross-feature Routing
다른 Feature 로 넘어가는 전환의 **유일한 조립 지점**. leaf 가 직접 못 하고 코디네이터를 경유하는 이유 → DocC `FeatureInterface`, [[architecture]] D1·D3.

대표 흐름 — **Users 상세 → 프로필 편집** (둘은 서로 import 하지 않는다):
1. `UsersFeature` 가 `delegate(.editProfile(id))` 방출 → AppFeature 수신
2. 앱 레벨 sheet 로 Profile 제시: `state.editProfile = ProfileFeature.State(profileId: id)` (`@Presents` + `.ifLet`)
3. 저장 완료 `editProfile(.presented(.delegate(.profileSaved(profile))))` → sheet 닫고 `users(.profileUpdated(profile))` 로 결과 통보

대표 흐름 — **로그인 완료 → 홈 전환**:
1. `AuthFeature`(가입 플로우 코디네이터)가 기존 회원 로그인 또는 가입 온보딩 완료 시 `delegate(.signedIn)` 방출 (→ [[auth#가입 플로우]])
2. AppFeature가 수신해 `state = State()`로 초기화 후 `root = .home` — 새 로그인은 새 세션이므로 이전 사용자의 in-memory State(화면·선택값)를 버린다

## Splash 세션 복구

앱 진입 판정은 `onAppear` 의 effect 하나다 — 버전 게이트 → 토큰 유무 → `pending` **한 콜**로 `State.root` 를 정한다. refresh 를 먼저 부르지 않는다 — Access 는 3시간이라 대부분 살아 있고, 만료면 이 콜의 403 을 AuthorizedNetworkClient 가 재발급·재시도로 흡수한다([[api#토큰 수명주기]]). 목적지 표·시퀀스는 [launch-routing](../docs/work/launch-routing.md), 게이트 규칙은 [[auth#게이트 2단 체인]].

`root` 가 Bool 2개가 아니라 **enum**(`splash`·`splashFailed`·`updateRequired`·`auth`·`home`)인 이유: 「판정 실패라 재시도해야 하는 상태」를 Bool 조합으로는 못 만든다.

- **버전 게이트가 세션 판정보다 먼저** — FORCE 를 뒤에 두면 이미 홈에 들어간 뒤에 막게 된다. 무인증 API 라 토큰과 무관하게 돌릴 수 있고, 실패는 **fail-open**(버전 정책 서버 장애가 앱 실행을 막지 않는다) → [[api#AppVersion]].
- **FORCE 는 `root = .updateRequired`** — 세션 판정을 시작하지 않는다. 알럿에 «나중에» 버튼을 만들지 않고, 스토어를 다녀와도 알럿을 다시 세워 차단을 유지한다. OPTIONAL 은 안내만 얹고 판정을 계속한다.

- **판정 실패는 두 갈래** — `ConsentError.sessionExpired`(자동 재발급까지 실패, 토큰은 인터셉터가 이미 폐기)는 재로그인, 네트워크·5xx 는 **판정 불가**라 토큰을 살린 채 `splashFailed`. 뭉뚱그리면 오프라인에서 앱을 켠 사용자가 로그아웃당한다.
- **`splashFailed` 에서 로그인 화면으로 내보내지 않는다** — 토큰이 살아 있으므로 `SplashView(onRetry:)` 자리에 머문다.
- **판정 결과는 `AuthFeature.State(resuming:)` 로 넘긴다** — 게이트 분기 코드는 코디네이터 한 곳에만 있고, AppFeature 는 목적지(login·resume·home·failed)만 고른다. 조회한 약관 항목도 함께 넘겨 화면이 `pending` 을 다시 부르지 않는다.
- 판정은 `consentClient`·`appVersionClient` 도 쓴다 — cross-feature 조립 자리라 Domain 의존이 여기 모인다(authClient 와 같은 이유).
- **Splash 계열 루트에서는 전역 로딩(`LoadingModal`)을 얹지 않는다** — 판정 API 가 도는 동안이 곧 Splash 가 떠 있는 이유라 로딩 판을 덮으면 브랜드 화면만 가리고, `.updateRequired` 는 알럿과 딤이 겹친다. `AppView.showsGlobalLoading` 이 `default` 없는 switch 라 루트가 늘면 컴파일이 깨져 판단을 강제한다 → [[domain.map#네트워킹 인프라]].

대표 흐름 — **dev 디버그 로그아웃** (Home 임시 버튼):
1. dev 계에서만 `AppFeature.onAppear` 가 `home.showsDebugLogout` 을 켜고, Home 로그아웃 버튼이 `delegate(.logoutRequested)` 방출
2. AppFeature 수신 → effect 에서 `authClient.logout()`(서버 로그아웃+토큰 Keychain 삭제)·`onboardingDraftStore.clear()`(온보딩 draft/UserDefaults 삭제). 서버 실패해도 로컬 정리는 진행(`try?`)
3. `sessionCleared` 로 `state = State()` 리셋 → `root = .auth` → 첫 소셜 로그인 화면 복귀. Splash 로 되돌리지 않는다(로그아웃 복귀는 판정이 아니라 확정 상태). cross-feature 조립이라 authClient 의존은 코디네이터인 여기서만 가진다 → [[home]]

대표 흐름 — **온보딩 위저드 진입**:
1. 발원지 3곳 — 「면접 시작」의 [시작하기](`interviewStartRequested`)·[수정하기](`interviewInfoEditRequested`)·dev 버튼(`onboardingRequested`). [시작하기]는 재사용 포폴 유무와 **무관하게** 위저드다: 면접 화면이 `sessionId` 로만 열리는데 그 id 를 만드는 건 위저드의 세션 생성뿐이라서다. «이전 정보 그대로» 세션 생성 API 가 생기면 `variant == .hasPortfolio` 는 수집을 건너뛴다(TODO — 미결 6-1)
2. AppFeature 수신 → `state.onboarding = OnboardingFeature.State(userName:)` (`@Presents` + `.ifLet`) → `AppView` 가 `fullScreenCover` 로 위저드 제시. 분기 재료(`variant`)는 홈이 진입 로드로 이미 정해 둔 값을 읽는다
3. 온보딩 `delegate(.finished(sessionId:))` = **세션 준비 완료** → 위저드 cover 를 닫고 그 자리에서 `state.interview = InterviewFeature.State(sessionId:)` 로 면접 cover 를 연다(홈은 안 태운다 — 어차피 가려지고, 갱신 시점은 면접이 끝나 돌아올 때다) → [[interview]]
4. 중도 이탈 `.dismiss` → cover 만 닫고 **`.home(.view(.onAppear))` 를 명시로 보내 홈을 다시 태운다** — STEP4 업로드는 끝났을 수 있는데 cover 를 닫는 것만으론 홈 `onAppear` 가 다시 오지 않아 «이전 정보 재사용» 카드가 옛 값으로 남는다. 홈 탭 위에서만 열리므로 **로그인 이후**라 토큰을 보유한다(온보딩 API 는 인증 필요) → [[onboarding]]
5. 면접 `delegate(.finished)`(리포트 대기 → 홈)·`.closed`(중단·실패 닫기) → 둘 다 cover 닫고 홈 재조회 — 어느 쪽이든 잔여가 줄었다. 정상 종료의 리포트 상세(r1) 연결은 `InterviewReportFeature` 통합 후(TODO)

→ 큰 그림은 [[domain.map]].

## 주의사항
코디네이터 패턴을 유지하기 위한 규칙.
- **Feature → Feature 의존 0.** 새 cross-feature 전환이 생기면 leaf Feature 엔 `delegate` case 만 추가하고, 조립(State 생성·제시·결과 통보)은 전부 여기서 한다. 직접 import/push 금지.
- 다른 Feature 의 reducer/State 를 구체 타입으로 참조해도 되는 **유일한 자리**(owner/코디네이터). leaf 끼리는 금지.
- 새 탭은 `State` / `Tab` / body `Scope` + `AppView` 의 `TabView` 에 추가. → DocC `AddingFeature`
