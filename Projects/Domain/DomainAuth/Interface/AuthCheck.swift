//
//  AuthCheck.swift
//  DomainAuthInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

/// GET /auth/check 응답 — JWT 인증이 동작하는지 확인하는 테스트용 엔드포인트.
public struct AuthCheck: Decodable, Equatable, Sendable {
    public let message: String?
    public let userId: UUID?

    public init(message: String?, userId: UUID?) {
        self.message = message
        self.userId = userId
    }
}
