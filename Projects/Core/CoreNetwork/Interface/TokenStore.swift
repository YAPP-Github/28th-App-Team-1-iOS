//
//  TokenStore.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import Foundation

/// 서버가 발급한 JWT 페어. Access 3시간 / Refresh 7일 (Rotation — 재발급 시 페어가 통째로 교체).
public struct AuthTokens: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// @lat: [[api#토큰 수명주기]]
// 토큰 보관소 — live 는 Keychain(Implementation). Feature 는 이 존재를 모른다.
// 첨부·자동 재발급은 AuthorizedNetworkClient 가, 저장(로그인)·삭제(로그아웃)는 AuthClient(DomainAuth) liveValue 가 수행한다.
public struct TokenStore: Sendable {
    public var load: @Sendable () throws -> AuthTokens?
    public var save: @Sendable (AuthTokens) throws -> Void
    public var clear: @Sendable () throws -> Void

    public init(
        load: @escaping @Sendable () throws -> AuthTokens?,
        save: @escaping @Sendable (AuthTokens) throws -> Void,
        clear: @escaping @Sendable () throws -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

extension TokenStore: TestDependencyKey {
    public static var testValue: TokenStore {
        TokenStore(
            load: unimplemented("TokenStore.load", placeholder: nil),
            save: unimplemented("TokenStore.save"),
            clear: unimplemented("TokenStore.clear")
        )
    }

    /// 프리뷰·Example·테스트용 인메모리 보관소 (프로세스 생존 동안만 유지)
    public static var inMemory: TokenStore {
        let box = LockIsolated<AuthTokens?>(nil)
        return TokenStore(
            load: { box.value },
            save: { tokens in box.setValue(tokens) },
            clear: { box.setValue(nil) }
        )
    }

    public static var previewValue: TokenStore { .inMemory }
}

public extension DependencyValues {
    var tokenStore: TokenStore {
        get { self[TokenStore.self] }
        set { self[TokenStore.self] = newValue }
    }
}

/// 저장된 토큰이 없는데 인증 필요 요청을 시도 — 로그인 화면 유도 신호.
public struct NotAuthenticatedError: Error, Equatable, Sendable {
    public init() {}
}
