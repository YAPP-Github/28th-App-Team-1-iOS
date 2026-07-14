# Auth 도메인 — 소셜 로그인 (DomainAuth · FeatureAuth)

카카오·애플 소셜 로그인으로 provider 자격증명을 받는 것까지 책임지는 도메인. 백엔드 세션 교환·토큰 영속화·자동 로그인은 다음 슬라이스로 미뤄졌다(백엔드 API 미동작으로 스코프 축소 — 백업: `wip/login-backend-snapshot-20260710`).

## 모듈 구성

공개 seam은 `AuthClient` 파사드 하나 — configure·handleOpenURL·signIn 세 엔드포인트. 소셜 SDK·시스템 프레임워크는 `DomainAuthImplementation`의 provider 클래스(KakaoLoginProvider·AppleLoginProvider)에 격리되고 Interface·Feature·App은 이를 모른다. → [[architecture]]

signIn은 `SocialCredential`을 반환한다 — provider별 발급물이 달라 enum이다: 카카오는 accessToken(백엔드 전송 예정)/refreshToken(SDK도 자체 보관), 애플은 identityToken(백엔드 검증용 JWT)/authorizationCode(백엔드가 애플 서버와 교환할 5분 TTL 일회성 코드). credential은 액션 payload로만 흐르고 State에 보관하지 않는다 — 백엔드 연동 시 signIn 내부 교환에 즉시 소비될 값이라, State의 토큰은 소비자 없는 죽은 데이터가 된다.

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

백엔드 세션 교환(`POST /api/v1/auth/social/login`)·Keychain 저장(TokenStore)·자동 로그인·refresh가 다음 슬라이스다. `signIn`의 반환값(`SocialCredential`)이 교환의 입력이 되는 이음새이며, 백업 브랜치에 CoreNetwork·TokenStore 구현이 보존돼 있다.
