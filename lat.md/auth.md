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

## AppFeature 통합

로그인 전/후를 루트 게이트로 분기한다 — `AppFeature.State.isAuthenticated`가 false면 `AuthView` 전체화면, true면 기존 TabView. `AuthFeature`가 `delegate(.signedIn)`을 올리면 AppFeature가 수신해 전환한다(cross-feature 조립은 AppFeature에서만). → [[app]]

## 다음 작업

세션 교환(`login`)·Keychain(TokenStore)·자동 재발급(refresh)은 #23 에서 Client 레벨로 구현됐다([[api#Auth]]). 남은 것은 Feature/App 배선이다.

- **AuthFeature 배선**: `signInFinished(.success(credential))` 뒤에 `authClient.login(credential)` 교환을 잇는다 — 현재는 credential 획득까지만 성공 처리하고 delegate(.signedIn)을 올린다.
- **자동 로그인**: AppFeature 게이트(`State.isAuthenticated`)를 `authClient.isAuthenticated()` 초기값으로 연결 — 지금은 앱 재실행 시 항상 false 다.
- **로그아웃 UX**: 설정 화면에서 `authClient.logout()` 호출 + 게이트 복귀.
