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

대표 흐름 — **온보딩 완주 → 면접 → 홈 복귀** (2026-08-03):
1. `OnboardingFeature` 가 분석까지 끝내고 `delegate(.finished(sessionId))` 방출 → 위저드를 닫고 `state.interview = InterviewFeature.State(sessionId:)` 로 fullScreenCover 제시 (`.dismiss` 는 위저드만 닫고 홈 재조회 — «온보딩 위저드 진입» 4)
2. 면접 종료 두 신호 모두 `state.interview = nil` + 홈 재조회(`.home(.view(.onAppear))`) — 어느 쪽이든 잔여가 줄었고 BACK_EXIT 이탈도 리포트를 만든다(2026-08-03 서버 계약). 케이스를 합치지 않는 건 정상 종료에 리포트 상세(r1) 라우팅이 붙을 자리라서다 → [[interview#코디네이터]]
3. **면접 커버 중에는 전역 LoadingModal 을 끈다**(`AppView.showsGlobalLoading`) — 답변 제출·질문 스트림마다 전역 딤이 덮이면 면접이 끊겨 보이고, 타이머가 도는 화면을 잠그는 것 자체가 오동작이다. 면접은 자체 진행 표시(상태 칩·초읽기)로 대기를 말한다.

대표 흐름 — **홈 위젯② → 리포트 상세** (2026-08-05):
1. `HomeFeature` 가 [레포트 보기] 를 `delegate(.reportDetailRequested(sessionId:))` 로 올린다 — 목록 행의 id 가 곧 세션 id 다(→ [[home#진입 로드]])
2. AppFeature 가 `state.report = ReportFeature.State(sessionId:)` 로 fullScreenCover 제시 (`@Presents` + `.ifLet` + `AppView`). 리포트는 자체 NavigationStack 을 갖는 전면 흐름이라 sheet 가 아니다
3. **채점 상태로 진입을 막지 않는다** — 미생성(404)·GENERATING 은 리포트 화면이 스스로 폴링해 채운다(→ [[report#1차 리포트]]). 홈이 걸러 내면 같은 판정이 두 곳에 생긴다
4. 되돌아오는 두 신호: `closeRequested` 는 커버만 닫고(리포트를 읽는 동안 잔여·목록이 바뀌지 않아 홈 재조회가 없다), 분석 부족의 `retryRequested` 는 커버를 닫고 «면접 시작» 과 같은 위저드를 태운다
5. **리포트 커버 중에도 전역 LoadingModal 을 끈다** — 채점 대기 중 4초 폴링마다 전역 딤이 깜빡이고, 그 대기는 리포트 화면이 `loadState` 로 이미 말한다

## 첫 실행 정리

앱을 삭제해도 iOS 는 Keychain 을 지우지 않는다 — 재설치하면 토큰만 살아남아 Splash 가 «기존 세션» 으로 판정하고, 방금 새로 설치한 사용자가 로그인 상태로 들어온다. UserDefaults 쪽(온보딩 draft)은 앱과 함께 사라지므로 로컬끼리도 어긋난다. 그래서 판정을 시작하기 전에 «이 설치의 첫 실행인가» 를 묻고, 첫 실행이면 잔존 로컬 데이터를 지운다.

- **판정 근거는 «앱과 함께 사라지는 저장소에 찍은 마커»** — `FirstLaunchStore`(CoreCommon)가 UserDefaults 에 마커를 두고 `isFirstLaunch()`/`markLaunched()` 만 노출한다. 마커가 없다 = 이 설치에서 아직 실행 안 됨. 마커를 Keychain 에 두면 재설치 후에도 남아 첫 실행을 영원히 놓친다.
- **무엇을 지울지는 마커가 모른다** — 정리 대상 선택은 코디네이터(`AppFeature.clearLocalData()`)의 판단이고, 스토어 계약은 판정만 맡는다. 대상은 **Keychain 전체**(`KeychainWipe.wipeAll()` — 아이템 클래스 5종)와 온보딩 draft.
- **Keychain 은 `tokenStore.clear()` 가 아니라 전체를 지운다** — 그건 `account: "auth-tokens"` 한 항목만 지우는데, 여기 목적은 «앱이 남긴 것 전부» 라 항목이 늘면 조용히 새는 쪽이 된다. 전체 폐기를 `TokenStore` 계약에 넣지 않은 건 토큰 스토어의 책임이 자기 항목이기 때문이고, 앱 전체를 비우는 판단은 composition root(App 타겟 `KeychainWipe`) 몫이다.
- **UserDefaults 는 도메인째 지우지 않는다** — 첫 실행 마커가 거기 있어 통째로 날리면 다음 실행이 다시 첫 실행으로 판정된다. 지우는 건 draft 처럼 대상을 아는 항목뿐.
- **마커는 정리를 마친 뒤 찍는다** — 사이에서 앱이 죽으면 다음 실행이 다시 첫 실행으로 판정돼 정리를 끝내는데, 먼저 찍으면 지우다 만 상태로 굳는다.
- **정리가 세션 판정보다 먼저** — `onAppear` 가 정리 effect 만 돌리고 `firstLaunchResolved` 로 갈라 그때 판정을 시작한다. 같은 effect 안에서 이으면 순서가 코드 배치에 묻힌다.
- 정리 함수는 **디버그 로그아웃과 공유**한다 — 지울 로컬 목록이 두 곳에서 갈라지면 한쪽만 늘어난다.

## Splash 세션 복구

앱 진입 판정은 `firstLaunchResolved` 의 effect 하나다 (그 앞에 [[app#첫 실행 정리]]가 선다) — 버전 게이트 → 토큰 유무 → `pending` **한 콜**로 `State.root` 를 정한다. refresh 를 먼저 부르지 않는다 — Access 는 3시간이라 대부분 살아 있고, 만료면 이 콜의 403 을 AuthorizedNetworkClient 가 재발급·재시도로 흡수한다([[api#토큰 수명주기]]). 목적지 표·시퀀스는 [launch-routing](../docs/work/launch-routing.md), 게이트 규칙은 [[auth#게이트 2단 체인]].

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
2. AppFeature 수신 → effect 에서 `authClient.logout()`(서버 로그아웃) 후 `clearLocalData()`(Keychain 전체·온보딩 draft — [[app#첫 실행 정리]]와 공유). 순서가 중요하다 — 로그아웃은 토큰이 있어야 서버에 닿으므로 Keychain 삭제보다 먼저다. 서버 실패해도 로컬 정리는 진행(`try?`)
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
