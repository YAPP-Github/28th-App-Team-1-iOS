//
//  AuthorizedNetworkClientLiveTests.swift
//  CoreNetworkTests
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import XCTest
@testable import CoreNetworkImplementation

final class AuthorizedNetworkClientLiveTests: XCTestCase {
    private func makeClient(
        tokenStore: TokenStore,
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> AuthorizedNetworkClient {
        withDependencies {
            $0.networkClient = NetworkClient(request: handler)
            $0.tokenStore = tokenStore
        } operation: {
            AuthorizedNetworkClient.liveValue
        }
    }

    func test_request_Bearer토큰을_첨부한다() async throws {
        let store = TokenStore.inMemory
        store.save(AuthTokens(accessToken: "access-1", refreshToken: "refresh-1"))
        let client = makeClient(tokenStore: store) { request in
            XCTAssertEqual(request.headers["Authorization"], "Bearer access-1")
            return Data("{}".utf8)
        }

        _ = try await client.request(NetworkRequest(path: "/api/v1/jobs"))
    }

    func test_request_저장된_토큰이_없으면_NotAuthenticatedError() async {
        let client = makeClient(tokenStore: .inMemory) { _ in Data() }

        do {
            _ = try await client.request(NetworkRequest(path: "/api/v1/jobs"))
            XCTFail("NotAuthenticatedError 가 나야 한다")
        } catch {
            XCTAssertTrue(error is NotAuthenticatedError)
        }
    }

    func test_request_TOKEN_EXPIRED면_재발급_후_1회_재시도한다() async throws {
        let store = TokenStore.inMemory
        store.save(AuthTokens(accessToken: "expired", refreshToken: "refresh-1"))
        let calls = LockIsolated<[String]>([])

        let client = makeClient(tokenStore: store) { request in
            calls.withValue { $0.append("\(request.method.rawValue) \(request.path) \(request.headers["Authorization"] ?? "-")") }
            switch (request.path, request.headers["Authorization"]) {
            case ("/api/v1/jobs", "Bearer expired"):
                let body = Data(#"{"success": false, "code": "TOKEN_EXPIRED", "message": "만료된 토큰입니다."}"#.utf8)
                throw NetworkError.statusCode(401, body)
            case ("/api/v1/auth/token/refresh", _):
                return Data(#"{"success": true, "data": {"accessToken": "access-2", "refreshToken": "refresh-2"}}"#.utf8)
            case ("/api/v1/jobs", "Bearer access-2"):
                return Data(#"{"success": true, "data": {"jobs": []}}"#.utf8)
            default:
                XCTFail("예상 밖 요청: \(request.path)")
                throw NetworkError.invalidURL
            }
        }

        _ = try await client.request(NetworkRequest(path: "/api/v1/jobs"))

        // Rotation — 재발급된 페어로 교체됐는지
        XCTAssertEqual(store.load(), AuthTokens(accessToken: "access-2", refreshToken: "refresh-2"))
        XCTAssertEqual(calls.value.count, 3)  // 원요청 → 재발급 → 재시도
    }

    func test_request_403이면_body코드와_무관하게_재발급_후_재시도한다() async throws {
        let store = TokenStore.inMemory
        store.save(AuthTokens(accessToken: "expired", refreshToken: "refresh-1"))
        let calls = LockIsolated<[String]>([])

        let client = makeClient(tokenStore: store) { request in
            calls.withValue { $0.append(request.path) }
            switch (request.path, request.headers["Authorization"]) {
            case ("/api/v1/consents/pending", "Bearer expired"):
                // 서버 계약(2026-08-02): 모든 API 에서 403 = 액세스 토큰 만료 — envelope 없는 body 도 트리거.
                throw NetworkError.statusCode(403, Data())
            case ("/api/v1/auth/token/refresh", _):
                return Data(#"{"success": true, "data": {"accessToken": "access-2", "refreshToken": "refresh-2"}}"#.utf8)
            case ("/api/v1/consents/pending", "Bearer access-2"):
                return Data(#"{"success": true, "data": {"status": "UP_TO_DATE", "items": []}}"#.utf8)
            default:
                XCTFail("예상 밖 요청: \(request.path)")
                throw NetworkError.invalidURL
            }
        }

        _ = try await client.request(NetworkRequest(path: "/api/v1/consents/pending"))

        XCTAssertEqual(store.load(), AuthTokens(accessToken: "access-2", refreshToken: "refresh-2"))
        XCTAssertEqual(calls.value.count, 3)  // 원요청 → 재발급 → 재시도
    }

    func test_request_재발급이_LOGIN_EXPIRED면_토큰을_폐기하고_던진다() async {
        let store = TokenStore.inMemory
        store.save(AuthTokens(accessToken: "expired", refreshToken: "dead"))

        let client = makeClient(tokenStore: store) { request in
            if request.path == "/api/v1/auth/token/refresh" {
                let body = Data(#"{"success": false, "code": "LOGIN_EXPIRED", "message": "다시 로그인해 주세요."}"#.utf8)
                throw NetworkError.statusCode(401, body)
            }
            let body = Data(#"{"success": false, "code": "TOKEN_EXPIRED", "message": "만료된 토큰입니다."}"#.utf8)
            throw NetworkError.statusCode(401, body)
        }

        do {
            _ = try await client.request(NetworkRequest(path: "/api/v1/jobs"))
            XCTFail("LOGIN_EXPIRED 가 나야 한다")
        } catch let error as ServerError {
            XCTAssertEqual(error.code, "LOGIN_EXPIRED")
            XCTAssertNil(store.load())  // 재로그인 필요 — 세션 잔해 제거
        } catch {
            XCTFail("예상 밖 에러: \(error)")
        }
    }

    func test_api_서버에러payload를_ServerError로_승격한다() async {
        let store = TokenStore.inMemory
        store.save(AuthTokens(accessToken: "access-1", refreshToken: "refresh-1"))
        let client = makeClient(tokenStore: store) { _ in
            let body = Data(#"{"success": false, "code": "PORTFOLIO_NOT_FOUND", "message": "포트폴리오를 찾을 수 없어요."}"#.utf8)
            throw NetworkError.statusCode(404, body)
        }

        do {
            try await client.api(NetworkRequest(path: "/api/v1/portfolios/x/status"))
            XCTFail("ServerError 가 나야 한다")
        } catch let error as ServerError {
            XCTAssertEqual(error.code, "PORTFOLIO_NOT_FOUND")
            XCTAssertEqual(error.statusCode, 404)
        } catch {
            XCTFail("예상 밖 에러: \(error)")
        }
    }
}
