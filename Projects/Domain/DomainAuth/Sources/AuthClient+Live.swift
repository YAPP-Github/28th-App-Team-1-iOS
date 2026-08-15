//
//  AuthClient+Live.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainAuthInterface
import DomainCommonInterface
import DomainConsentInterface
import Foundation

// @lat: [[api#Auth]]
// depends-on: [[api#토큰 수명주기]] (TokenStore 저장·삭제는 여기, 첨부·자동 재발급은 AuthorizedNetworkClient)
extension AuthClient: @retroactive DependencyKey {
    public static var liveValue: AuthClient {
        @Dependency(\.networkClient) var network
        @Dependency(\.authorizedNetworkClient) var authorizedNetwork
        @Dependency(\.tokenStore) var tokenStore

        /// `login`·`loginWithReviewCode` 공통 후처리 — 세션 교환 요청을 보내고 토큰 페어를 저장한 뒤
        /// 라우팅 판정값만 남긴다. 두 진입점의 차이는 body 의 `provider`·`credential` 뿐이다.
        @Sendable func exchange(_ body: LoginBody) async throws -> LoginResult {
            try await AuthError.mapping {
                let request = try NetworkRequest.json(
                    method: .post,
                    path: "/api/v1/auth/social/login",
                    body: body
                )
                let response: LoginResponse = try await network.api(request)
                try tokenStore.save(AuthTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                ))
                return LoginResult(
                    consentStatus: response.consentStatus,
                    profileRegistered: response.profileRegistered
                )
            }
        }

        return AuthClient(
            configure: { appKey in
                KakaoLoginProvider.configure(appKey: appKey)
            },
            handleOpenURL: { url in
                KakaoLoginProvider.handleOpenURL(url)
            },
            signIn: { provider in
                switch provider {
                case .kakao:
                    return try await KakaoLoginProvider().performLogin()
                case .apple:
                    return try await AppleLoginProvider().performLogin()
                }
            },
            login: { credential in
                try await exchange(credential.loginBody)
            },
            loginWithReviewCode: { code in
                // provider 는 KAKAO 그대로 — 서버가 credential 값으로 심사 코드를 갈라낸다(전용 provider 없음).
                try await exchange(LoginBody(provider: "KAKAO", credential: code))
            },
            refresh: {
                try await AuthError.mapping {
                    guard let tokens = try tokenStore.load() else { throw NotAuthenticatedError() }
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/auth/token/refresh",
                        body: RefreshBody(refreshToken: tokens.refreshToken)
                    )
                    do {
                        let renewed: AuthTokens = try await network.api(request)
                        try tokenStore.save(renewed)
                    } catch let error as ServerError where error.code == "LOGIN_EXPIRED" {
                        try tokenStore.clear()  // 리프레시도 만료 — 재로그인 필요
                        throw error
                    }
                }
            },
            logout: {
                // Access Token 은 만료까지 서버에서 유효 — 클라이언트 토큰은 서버 응답과 무관하게 반드시 삭제 (Swagger 명세)
                defer { try? tokenStore.clear() }
                try await AuthError.mapping {
                    try await authorizedNetwork.api(NetworkRequest(method: .delete, path: "/api/v1/auth/logout"))
                }
            },
            check: {
                try await AuthError.mapping {
                    try await authorizedNetwork.api(NetworkRequest(path: "/api/v1/auth/check"))
                }
            },
            isAuthenticated: {
                (try? tokenStore.load()) != nil
            }
        )
    }
}

// MARK: - 서버 계약 매핑

/// `provider` 는 D14 계약의 열거값(KAKAO·APPLE). 심사용 코드도 KAKAO 로 보낸다 —
/// 전용 provider 가 없어 서버가 credential 값으로 갈라낸다. → [[auth#심사용 코드 로그인]]
private struct LoginBody: Encodable, Sendable {
    let provider: String
    let credential: String
}

/// 로그인 응답 — 토큰 페어(TokenStore 행)와 라우팅 판정값(LoginResult 행)만 읽는다.
/// `newUser`·`userInfo` 등 나머지 필드는 소비자가 없어 디코딩하지 않는다 (홈 초기 데이터는 진입 후 조회).
private struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let consentStatus: ConsentPendingStatus
    let profileRegistered: Bool
}

private struct RefreshBody: Encodable {
    let refreshToken: String
}

private extension SocialCredential {
    /// D14 계약: KAKAO 는 카카오 액세스 토큰, APPLE 은 authorization code 를 `credential` 로 보낸다.
    /// (애플 identityToken 은 보내지 않는다 — 서버가 코드 교환으로 검증)
    var loginBody: LoginBody {
        switch self {
        case .kakao(let accessToken, _):
            LoginBody(provider: "KAKAO", credential: accessToken)
        case .apple(_, let authorizationCode, _):
            LoginBody(provider: "APPLE", credential: authorizationCode)
        }
    }
}
