//
//  AuthClient.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import Foundation

/// 인증 파사드. 소셜 로그인 자격증명 획득, SDK 수명주기 접점(configure·handleOpenURL),
/// 서버 세션 수명주기(login·refresh·logout — D14 `/api/v1/auth/**`)를 하나의 seam으로 노출한다.
/// 카카오 SDK는 DomainAuthImplementation(KakaoLoginProvider)에, 토큰 보관·자동 재발급은
/// CoreNetwork(TokenStore·AuthorizedNetworkClient)에 격리된다 — Feature 는 토큰의 존재를 모른다.
// @lat: [[api#Auth]]
public struct AuthClient: Sendable {
    /// 앱 시작 시 1회 — 카카오 SDK 초기화. liveValue 사용 전에 선행돼야 한다.
    /// 애플 로그인은 초기화가 필요 없다 — 이 접점은 카카오 전용이다.
    public var configure: @MainActor @Sendable (_ appKey: String) -> Void
    /// 소셜 로그인 콜백 URL 처리. 카카오 콜백이면 SDK에 전달, 아니면 무시.
    /// 애플 로그인은 시스템 시트가 자체 처리해 콜백 URL이 없다.
    public var handleOpenURL: @MainActor @Sendable (URL) -> Void
    /// 소셜 로그인 → provider가 발급한 자격증명(SocialCredential) 반환.
    /// 이 반환값이 `login`(서버 세션 교환)의 입력이 된다.
    public var signIn: @Sendable (SocialProvider) async throws -> SocialCredential
    /// 자격증명을 서버 세션으로 교환 (POST /auth/social/login) — 성공 시 토큰 페어를 TokenStore 에 저장하고
    /// 라우팅 판정값(동의 상태·프로필 등록 여부)을 돌려준다. 실패는 `AuthError` 로 매핑된다.
    public var login: @Sendable (SocialCredential) async throws -> LoginResult
    /// 심사용 코드를 서버 세션으로 교환 (`login` 과 같은 엔드포인트·같은 `provider=KAKAO`) — 소셜 OAuth 를
    /// 거치지 않고 서버가 지정해 둔 데모 계정에 붙는다. 토큰 저장·판정값 반환은 `login` 과 동일하다.
    /// 코드는 심사자가 화면에서 직접 입력한다 — 앱 바이너리에 심어두지 않는다. → [[auth#심사용 코드 로그인]]
    public var loginWithReviewCode: @Sendable (_ code: String) async throws -> LoginResult
    /// 명시적 토큰 재발급 (POST /auth/token/refresh) — 만료 시 자동 재발급은 AuthorizedNetworkClient 가 수행.
    public var refresh: @Sendable () async throws -> Void
    /// 로그아웃 (DELETE /auth/logout) — 서버 Refresh Token 삭제. 로컬 토큰은 성공 여부와 무관하게 삭제한다.
    public var logout: @Sendable () async throws -> Void
    /// 인증 동작 확인 (GET /auth/check, 테스트용).
    public var check: @Sendable () async throws -> AuthCheck
    /// 로컬 토큰 존재 여부 — 앱 진입 게이트(로그인/메인) 분기. → [[app]]
    public var isAuthenticated: @Sendable () -> Bool

    public init(
        configure: @escaping @MainActor @Sendable (_ appKey: String) -> Void,
        handleOpenURL: @escaping @MainActor @Sendable (URL) -> Void,
        signIn: @escaping @Sendable (SocialProvider) async throws -> SocialCredential,
        login: @escaping @Sendable (SocialCredential) async throws -> LoginResult,
        loginWithReviewCode: @escaping @Sendable (_ code: String) async throws -> LoginResult,
        refresh: @escaping @Sendable () async throws -> Void,
        logout: @escaping @Sendable () async throws -> Void,
        check: @escaping @Sendable () async throws -> AuthCheck,
        isAuthenticated: @escaping @Sendable () -> Bool
    ) {
        self.configure = configure
        self.handleOpenURL = handleOpenURL
        self.signIn = signIn
        self.login = login
        self.loginWithReviewCode = loginWithReviewCode
        self.refresh = refresh
        self.logout = logout
        self.check = check
        self.isAuthenticated = isAuthenticated
    }
}

extension AuthClient: TestDependencyKey {}

extension DependencyValues {
    public var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
