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
import Foundation

// @lat: [[api#Auth]]
// depends-on: [[api#토큰 수명주기]] (TokenStore 저장·삭제는 여기, 첨부·자동 재발급은 AuthorizedNetworkClient)
extension AuthClient: @retroactive DependencyKey {
    public static var liveValue: AuthClient {
        @Dependency(\.networkClient) var network
        @Dependency(\.authorizedNetworkClient) var authorizedNetwork
        @Dependency(\.tokenStore) var tokenStore

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
                try await AuthError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/auth/social/login",
                        body: credential.loginBody
                    )
                    let tokens: AuthTokens = try await network.api(request)
                    try tokenStore.save(tokens)
                }
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

private struct LoginBody: Encodable {
    let provider: String
    let credential: String
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
        case .apple(_, let authorizationCode):
            LoginBody(provider: "APPLE", credential: authorizationCode)
        }
    }
}
