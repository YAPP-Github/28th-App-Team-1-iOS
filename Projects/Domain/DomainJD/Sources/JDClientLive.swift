//
//  JDClientLive.swift
//  DomainJDImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainJDInterface
import Foundation

// @lat: [[api#JD]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension JDClient: @retroactive DependencyKey {
    public static var liveValue: JDClient {
        @Dependency(\.authorizedNetworkClient) var network

        return JDClient(
            validate: { jdURL in
                try await mappingJDError {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/jd/validate",
                        body: ValidateBody(jdUrl: jdURL)
                    )
                    return try await network.api(request)
                }
            }
        )
    }
}

private struct ValidateBody: Encodable {
    let jdUrl: String
}

// MARK: - 에러 매핑

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(JDError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingJDError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw JDError(mapping: error)
    }
}

private extension JDError {
    /// 서버 에러 코드 → 고정 케이스 (JD 는 문구 노출형 검증군이 없다 — 전부 고정 매핑).
    static let serverCodeMap: [String: JDError] = [
        "INVALID_JD_URL": .invalidURL,
        "JD_VALIDATION_LIMIT_EXCEEDED": .dailyLimitExceeded,
        "LOGIN_EXPIRED": .sessionExpired,
        "TOKEN_EXPIRED": .sessionExpired,
        "INVALID_TOKEN": .sessionExpired
    ]

    init(mapping error: any Error) {
        switch error {
        case let error as JDError:
            self = error
        case let error as ServerError:
            self = Self.serverCodeMap[error.code]
                ?? (error.statusCode >= 500 ? .serverUnavailable : .unexpected)
        case is NotAuthenticatedError:
            self = .sessionExpired
        case let error as NetworkError:
            self.init(networkError: error)
        default:
            self = .unexpected
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
