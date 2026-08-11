//
//  TokenStoreLive.swift
//  CoreNetworkImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import Foundation
import Security

extension TokenStore: @retroactive DependencyKey {
    /// Keychain 보관 — 토큰은 UserDefaults 에 두지 않는다.
    public static var liveValue: TokenStore {
        let keychain = KeychainTokenStore(
            service: Bundle.main.bundleIdentifier ?? "com.hilit.app",
            account: "auth-tokens"
        )
        return TokenStore(
            load: { try keychain.load() },
            save: { try keychain.save($0) },
            clear: { try keychain.clear() }
        )
    }
}

// MARK: - Keychain

enum KeychainError: Error {
    case operationFailed(OSStatus)
    case decodingFailed(Error)
    case encodingFailed(Error)
}

private final class KeychainTokenStore: Sendable {
    private let service: String
    private let account: String

    init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func load() throws -> AuthTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        // 아이템이 없으면 nil 반환 (에러 아님)
        if status == errSecItemNotFound {
            return nil
        }

        // 다른 실패는 에러
        guard status == errSecSuccess else {
            throw KeychainError.operationFailed(status)
        }

        guard let data = item as? Data else {
            return nil
        }

        do {
            return try JSONDecoder().decode(AuthTokens.self, from: data)
        } catch {
            throw KeychainError.decodingFailed(error)
        }
    }

    func save(_ tokens: AuthTokens) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(tokens)
        } catch {
            throw KeychainError.encodingFailed(error)
        }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            // 기기 잠금 해제 후 접근 가능 + 이 기기 한정 (백업 이전 금지)
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            attributes.forEach { addQuery[$0.key] = $0.value }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.operationFailed(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.operationFailed(status)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        // 아이템이 없으면 성공으로 간주 (이미 삭제됨)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.operationFailed(status)
        }
    }
}
