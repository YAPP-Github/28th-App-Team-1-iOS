//
//  UserClientLive.swift
//  DomainUserImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainUserInterface
import Foundation

// @lat: [[api#User]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension UserClient: @retroactive DependencyKey {
    public static var liveValue: UserClient {
        @Dependency(\.authorizedNetworkClient) var network

        return UserClient(
            profile: {
                try await mappingUserError {
                    try await network.api(NetworkRequest(path: "/api/v1/users/me/profile"))
                }
            },
            updateProfile: { update in
                try await mappingUserError {
                    let request = try NetworkRequest.json(
                        method: .patch,
                        path: "/api/v1/users/me/profile",
                        body: update
                    )
                    try await network.api(request)
                }
            },
            registerName: { name in
                try await mappingUserError {
                    let request = try NetworkRequest.json(
                        method: .patch,
                        path: "/api/v1/users/me/name",
                        body: NameBody(name: name)
                    )
                    try await network.api(request)
                }
            },
            checkName: { name in
                try await mappingUserError {
                    let request = NetworkRequest(
                        path: "/api/v1/users/name/check",
                        queryItems: [URLQueryItem(name: "name", value: name)]
                    )
                    let payload: NameCheckPayload = try await network.api(request)
                    return payload.available
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

private struct NameBody: Encodable {
    let name: String
}

private struct NameCheckPayload: Decodable, Sendable {
    let available: Bool
}

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(UserError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingUserError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw UserError(mapping: error)
    }
}

private extension UserError {
    /// 서버 에러 코드 → 고정 케이스. 입력 검증군(서버 문구 노출)은 `validationCodes` 로 분리.
    static let serverCodeMap: [String: UserError] = [
        "USER_NOT_FOUND": .userNotFound,
        "NAME_ALREADY_TAKEN": .nameAlreadyTaken,
        "INVALID_JOB_ROLE": .invalidJobRole,
        "LOGIN_EXPIRED": .sessionExpired,
        "TOKEN_EXPIRED": .sessionExpired,
        "INVALID_TOKEN": .sessionExpired
    ]

    static let validationCodes: Set<String> = ["VALIDATION_ERROR", "CONSTRAINT_VIOLATION"]

    init(mapping error: any Error) {
        switch error {
        case let error as UserError:
            self = error
        case let error as ServerError:
            self.init(serverError: error)
        case is NotAuthenticatedError:
            self = .sessionExpired
        case let error as NetworkError:
            self.init(networkError: error)
        default:
            self = .unexpected
        }
    }

    init(serverError error: ServerError) {
        if let fixed = Self.serverCodeMap[error.code] {
            self = fixed
        } else if Self.validationCodes.contains(error.code) {
            self = .invalid(message: error.message)
        } else {
            self = error.statusCode >= 500 ? .serverUnavailable : .unexpected
        }
    }

    init(networkError error: NetworkError) {
        switch error {
        case .transport:
            self = .networkFailure
        case .statusCode(let status, _) where status >= 500:
            self = .serverUnavailable
        default:
            self = .unexpected
        }
    }
}
