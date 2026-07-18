//
//  AuthorizedNetworkClientLive.swift
//  CoreNetworkImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import Foundation

// @lat: [[api#토큰 수명주기]]
extension AuthorizedNetworkClient: @retroactive DependencyKey {
    public static var liveValue: AuthorizedNetworkClient {
        @Dependency(\.networkClient) var networkClient
        @Dependency(\.tokenStore) var tokenStore
        let engine = AuthorizedEngine(networkClient: networkClient, tokenStore: tokenStore)
        return AuthorizedNetworkClient(
            request: { try await engine.request($0) },
            authorizedResource: { path in try await engine.authorizedResource(path: path) }
        )
    }
}

// MARK: - Engine

/// Bearer 첨부 · 만료 감지 · 단일 비행 재발급을 담당한다. HTTP 자체는 base `NetworkClient` 에 위임.
final class AuthorizedEngine: Sendable {
    /// 재발급 트리거가 되는 서버 에러 코드 (Swagger `토큰 재발급` 명세)
    private static let refreshTriggerCodes: Set<String> = ["TOKEN_EXPIRED", "INVALID_TOKEN"]
    private static let refreshPath = "/api/v1/auth/token/refresh"
    private static let loginExpiredCode = "LOGIN_EXPIRED"

    private let networkClient: NetworkClient
    private let tokenStore: TokenStore
    private let refresher = SingleFlight()

    init(networkClient: NetworkClient, tokenStore: TokenStore) {
        self.networkClient = networkClient
        self.tokenStore = tokenStore
    }

    func request(_ request: NetworkRequest) async throws -> Data {
        try await perform(request, allowsRefresh: true)
    }

    func authorizedResource(path: String) async throws -> AuthorizedResource {
        guard let tokens = tokenStore.load() else { throw NotAuthenticatedError() }
        let baseURL = try NetworkClient.defaultBaseURL()
        guard let url = try NetworkRequest(path: path).urlRequest(baseURL: baseURL).url else {
            throw NetworkError.invalidURL
        }
        return AuthorizedResource(url: url, headers: ["Authorization": "Bearer \(tokens.accessToken)"])
    }

    private func perform(_ request: NetworkRequest, allowsRefresh: Bool) async throws -> Data {
        guard let tokens = tokenStore.load() else { throw NotAuthenticatedError() }
        var authorized = request
        authorized.headers["Authorization"] = "Bearer \(tokens.accessToken)"
        do {
            return try await networkClient.request(authorized)
        } catch let error as NetworkError {
            guard allowsRefresh,
                  case .statusCode(let status, let body) = error,
                  let serverError = ServerError.decode(statusCode: status, body: body),
                  Self.refreshTriggerCodes.contains(serverError.code)
            else { throw error }
            try await refreshTokens()
            return try await perform(request, allowsRefresh: false)
        }
    }

    /// Rotation 재발급 — 성공 시 새 페어 저장. `LOGIN_EXPIRED`(리프레시도 만료)면 토큰 폐기 후 전파.
    /// 동시 다발 만료에서 재발급이 한 번만 나가도록 직렬화한다 — 기존 Refresh Token 이
    /// 재발급 즉시 만료되므로(Rotation) 중복 재발급은 로그아웃 사고로 이어진다.
    private func refreshTokens() async throws {
        do {
            try await refresher.run { [networkClient, tokenStore] in
                guard let tokens = tokenStore.load() else { throw NotAuthenticatedError() }
                let request = try NetworkRequest.json(
                    method: .post,
                    path: Self.refreshPath,
                    body: RefreshBody(refreshToken: tokens.refreshToken)
                )
                let renewed: AuthTokens = try await networkClient.api(request)
                tokenStore.save(renewed)
            }
        } catch let error as ServerError where error.code == Self.loginExpiredCode {
            tokenStore.clear()  // 재로그인 필요 — 세션 잔해 제거
            throw error
        }
    }
}

private struct RefreshBody: Encodable {
    let refreshToken: String
}

// MARK: - Single-flight

private actor SingleFlight {
    private var inFlight: Task<Void, Error>?

    func run(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        if let inFlight {
            return try await inFlight.value  // 진행 중인 재발급에 합류
        }
        let task = Task { try await operation() }
        inFlight = task
        defer { inFlight = nil }
        try await task.value
    }
}
