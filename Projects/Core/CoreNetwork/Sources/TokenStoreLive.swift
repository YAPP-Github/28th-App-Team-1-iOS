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
            load: { keychain.load() },
            save: { keychain.save($0) },
            clear: { keychain.clear() }
        )
    }
}

// MARK: - Keychain

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

    func load() -> AuthTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }

    func save(_ tokens: AuthTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            // 기기 잠금 해제 후 접근 가능 + 이 기기 한정 (백업 이전 금지)
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            attributes.forEach { addQuery[$0.key] = $0.value }
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
