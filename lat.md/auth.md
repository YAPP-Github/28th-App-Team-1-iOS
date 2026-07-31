# Auth 도메인 — 소셜 로그인 (DomainAuth · FeatureAuth)

카카오·애플 소셜 로그인(자격증명 획득)과 서버 세션 수명주기(교환·재발급·로그아웃 — [[api#Auth]])를 책임지는 도메인. 토큰 영속화는 Keychain(TokenStore), 만료 시 자동 재발급은 AuthorizedNetworkClient — 둘 다 CoreNetwork 인프라다([[api#토큰 수명주기]]).

## 모듈 구성

공개 seam은 `AuthClient` 파사드 하나 — SDK 접점(configure·handleOpenURL·signIn)과 서버 세션(login·refresh·logout·check·isAuthenticated). → [[architecture]]

소셜 SDK·시스템 프레임워크는 `DomainAuthImplementation`의 provider 클래스(KakaoLoginProvider·AppleLoginProvider)에 격리되고 Interface·Feature·App은 이를 모른다.

signIn은 `SocialCredential`을 반환한다 — provider별 발급물이 달라 enum이다: 카카오는 accessToken(login 교환의 credential)/refreshToken(SDK도 자체 보관), 애플은 identityToken(백엔드 검증용 JWT)/authorizationCode(백엔드가 애플 서버와 교환할 5분 TTL 일회성 코드 — D14 는 이것을 credential 로 받는다). credential은 액션 payload로만 흐르고 State에 보관하지 않는다 — `login(credential)` 교환에 즉시 소비될 값이라, State의 토큰은 소비자 없는 죽은 데이터가 된다.

login 성공 시 토큰 페어는 TokenStore(Keychain)로 들어가고 Feature 는 토큰을 만지지 않는다. 서버 에러는 `AuthError` 로 매핑된다(invalidCredential·sessionExpired·serverUnavailable·networkFailure) — 매핑표는 [[api#Auth]].

## Provider 확장 지점

`SocialProvider` enum과 Implementation 내부 `SocialLoginProvider` protocol이 확장 자리다. 애플 로그인이 이 지점으로 추가됐다 — `case apple` + `AppleLoginProvider` + signIn switch 한 갈래. 카카오 로그인 흐름은 무변경(SocialCredential enum 마이그레이션으로 생성 문법 1곳만 갱신). 다음 provider도 같은 경로로 늘어난다.

## 카카오 로그인 흐름

`KakaoLoginProvider`가 `UserApi.isKakaoTalkLoginAvailable()`로 카카오톡 앱/웹 로그인을 분기한다. SDK의 `SdkError`는 이 파일 안에서만 소비된다 — 취소(`ClientFailed(.Cancelled)`)만 `AuthError.cancelled`로 구분해 얼럿 없이 조용히 복귀하고, 나머지는 `.unexpected`로 정규화된다.

SDK 수명주기 접점(초기화 `configure`·콜백 전달 `handleOpenURL`)도 `AuthClient` 엔드포인트다 — App은 lifecycle 이벤트를 seam에 연결만 하고 KakaoSDK를 직접 import하지 않는다.

알려진 한계: 카카오톡 앱 로그인에서 승인/거부 없이 앱 스위처로 복귀하면 SDK completion이 불리지 않아 로딩이 유지된다 — 유예기간 처리는 다음 마일스톤(백업 브랜치의 lat.md/auth.md 참조).

## 애플 로그인 흐름

`AppleLoginProvider`가 `ASAuthorizationController`를 continuation으로 감싼다. 취소(`ASAuthorizationError.canceled`)만 `AuthError.cancelled`로 구분해 얼럿 없이 복귀하고, 나머지는 `.unexpected`로 정규화된다 — ASAuthorization 타입은 이 파일 밖으로 나가지 않는다.

카카오와 달리 SDK 초기화·콜백 URL이 없어 configure/handleOpenURL은 카카오 전용으로 남는다. name/email 스코프는 요청하지 않는다 — 이 슬라이스엔 소비자가 없고, 최초 승인에만 오는 값이지만 출시 전이라 설정에서 revoke 후 재승인으로 재획득 가능하다. 백엔드 수신 필드가 확정되면 스코프와 payload를 함께 확장한다.

Sign in with Apple entitlement가 App 타겟에 필요하다(`TargetFactory.entitlements` — 시뮬레이터는 entitlement만으로 동작, 실기기는 Apple Developer 포털에서 App ID capability 활성화 필요). Example 앱은 스텁 authClient라 entitlement이 없다.

## 가입 플로우

PRD Part 6·7 확정(2026-07-31)으로 FeatureAuth 가 로그인 단일 화면에서 가입·계정 플로우 전체로 확장됐다. 화면 매핑·미결의 단일 소스는 [home-account](../docs/work/home-account.md) §2 — 여기는 구현 구조만. UI 는 전부 Figma 수령 전 골격이다.

`AuthFeature` 가 플로우 코디네이터다 — 루트 `AuthCreateAccountFeature`(A0 소셜 로그인, 구 AuthFeature 개명) + `path`(StackState)로 가입 경로(terms → naming → job → experience → register)를 push 한다. 수집값(이름·직군·연차)은 코디네이터가 누적만 한다 — 서버 제출 시점(화면별 즉시 vs 일괄)이 미결이라서.

- `AuthTermsFeature`(A1) — 필수 5종 체크·전체 동의·전문 바텀시트(DS `.hilitBottomSheet`). 제출 API(=계정 생성 확정)는 S-1 협의 후 DomainAuth 확장.
- `AuthOnboarding{Naming·Job·Experience·Register}` — `Sources/Onboarding/` 폴더. Job·Experience 는 FeatureOnboarding STEP1·2 의 **복사본**(Feature 간 공유 금지 — 원본은 위저드 정리 시 제거, [[onboarding]]). Naming 은 `UserClient.registerName`·`checkName` 배선 대기.
- `AuthSuspensionFeature`(A4) — 정지 안내. Path 밖 — 진입이 홈 게이트(`ACCOUNT_SUSPENDED`)라 제시는 AppFeature(cross-feature). CS 메일 주소는 placeholder.
- `SplashView` — 상태 없는 정적 뷰. 자동 로그인 판정은 AppFeature 몫.
- 신규/기존 회원 분기는 login 응답 계약(S-1) 대기 — 지금은 authenticated 시 전원 신규 취급으로 terms 진입(코디네이터 TODO).

## AppFeature 통합

Splash 판정 → 로그인 전/후 루트 게이트로 분기한다. 판정 동안 `SplashView`, 미인증이면 `AuthView`(가입 플로우 스택) 전체화면, 인증됐으면 TabView. → [[app]]

`AppFeature.onAppear` 가 `authClient.isAuthenticated()`(Keychain 토큰 유무)로 `State.isAuthenticated` 초기값을 정하고 `isCheckingSession` 을 내린다. `AuthFeature`(코디네이터)가 가입 완료 또는 기존 회원 로그인 시 `delegate(.signedIn)`을 올리면 AppFeature 가 수신해 전환한다(cross-feature 조립은 AppFeature에서만).

## 다음 작업

세션 교환(`login`)·자동 재발급·AuthFeature signIn→login 배선·자동 로그인(Splash)·가입 플로우 화면 골격은 완료([[auth#가입 플로우]]). 남은 것:

- **동의 제출·신규/기존 분기 API(S-1)**: DomainAuth 확장 + 코디네이터 분기 교체 — 서버 협의 후.
- **프로필 제출 시점**: 이름·직군·연차를 화면별 즉시 vs 등록 완료 일괄 — 확정 시 `UserClient.registerName`·`updateProfile` 배선.
- **Figma UI 연결**: 가입 플로우 8화면(Splash·CreateAccount·Terms+전문시트·Suspension·이름·직군·연차·등록완료)은 시안 교체 완료(2026-07-31, figma-screen). 남은 것은 A0 실패 alert → 토스트 교체.
- **로그아웃 UX**: 설정 화면(Part 5)에서 `authClient.logout()` 호출 + 게이트 복귀.
