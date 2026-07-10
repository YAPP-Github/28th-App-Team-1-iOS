# Auth 도메인 — 소셜 로그인 (DomainAuth · FeatureAuth)

카카오 소셜 로그인으로 provider AT/RT를 받는 것까지 책임지는 도메인. 백엔드 세션 교환·토큰 영속화·자동 로그인은 다음 슬라이스로 미뤄졌다(백엔드 API 미동작으로 스코프 축소 — 백업: `wip/login-backend-snapshot-20260710`).

## 모듈 구성

공개 seam은 `AuthClient` 파사드 하나 — configure·handleOpenURL·signIn 세 엔드포인트. 카카오 SDK는 `DomainAuthImplementation`의 `KakaoLoginProvider`에 격리되고 Interface·Feature·App은 SDK를 모른다. → [[architecture]]

signIn은 `SocialCredential`(provider·accessToken·refreshToken)을 반환한다. credential은 액션 payload로만 흐르고 State에 보관하지 않는다 — 백엔드 연동 시 카카오 AT는 signIn 내부 교환에 즉시 소비되고 카카오 RT는 SDK TokenManager가 자체 관리하므로, State의 토큰은 소비자 없는 죽은 데이터가 된다.

## Provider 확장 지점

`SocialProvider` enum과 Implementation 내부 `SocialLoginProvider` protocol이 확장 자리다. 애플 로그인 추가 시 `case apple` + `AppleLoginProvider` + signIn의 provider switch 한 갈래만 늘어나고, 카카오 관련 코드는 손대지 않는다.

## 카카오 로그인 흐름

`KakaoLoginProvider`가 `UserApi.isKakaoTalkLoginAvailable()`로 카카오톡 앱/웹 로그인을 분기한다. SDK의 `SdkError`는 이 파일 안에서만 소비된다 — 취소(`ClientFailed(.Cancelled)`)만 `AuthError.cancelled`로 구분해 얼럿 없이 조용히 복귀하고, 나머지는 `.unexpected`로 정규화된다.

SDK 수명주기 접점(초기화 `configure`·콜백 전달 `handleOpenURL`)도 `AuthClient` 엔드포인트다 — App은 lifecycle 이벤트를 seam에 연결만 하고 KakaoSDK를 직접 import하지 않는다.

알려진 한계: 카카오톡 앱 로그인에서 승인/거부 없이 앱 스위처로 복귀하면 SDK completion이 불리지 않아 로딩이 유지된다 — 유예기간 처리는 다음 마일스톤(백업 브랜치의 lat.md/auth.md 참조).

## AppFeature 통합

로그인 전/후를 루트 게이트로 분기한다 — `AppFeature.State.isAuthenticated`가 false면 `AuthView` 전체화면, true면 기존 TabView. `AuthFeature`가 `delegate(.signedIn)`을 올리면 AppFeature가 수신해 전환한다(cross-feature 조립은 AppFeature에서만). → [[app]]

## 다음 작업

백엔드 세션 교환(`POST /api/v1/auth/social/login`)·Keychain 저장(TokenStore)·자동 로그인·refresh가 다음 슬라이스다. `signIn`의 반환값(`SocialCredential`)이 교환의 입력이 되는 이음새이며, 백업 브랜치에 CoreNetwork·TokenStore 구현이 보존돼 있다.
