//
//  FeedbackShareClientLive.swift
//  DomainFeedbackShareImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainFeedbackShareInterface
import Foundation

// @lat: [[api#Feedback Share]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension FeedbackShareClient: @retroactive DependencyKey {
    public static var liveValue: FeedbackShareClient {
        @Dependency(\.authorizedNetworkClient) var network

        return FeedbackShareClient(
            status: { sessionId in
                try await mappingFeedbackShareError {
                    try await network.api(
                        NetworkRequest(path: "/api/v1/feedback/sessions/\(sessionId)/share")
                    )
                }
            },
            create: { sessionId, axes in
                try await mappingFeedbackShareError {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/feedback/sessions/\(sessionId)/share",
                        body: CreateBody(axes: axes)
                    )
                    return try await network.api(request)
                }
            },
            makePrivate: { sessionId in
                try await mappingFeedbackShareError {
                    let request = try NetworkRequest.json(
                        method: .patch,
                        path: "/api/v1/feedback/sessions/\(sessionId)/share",
                        body: UpdateBody(status: "PRIVATE")
                    )
                    try await network.api(request)
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

private struct CreateBody: Encodable {
    let axes: [String]
}

private struct UpdateBody: Encodable {
    let status: String
}

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(FeedbackShareError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingFeedbackShareError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw FeedbackShareError(mapping: error)
    }
}

private extension FeedbackShareError {
    /// 서버 에러 코드 → 고정 케이스. 항목 검증군(서버 문구 노출)은 `axesCodes` 로 분리.
    static let serverCodeMap: [String: FeedbackShareError] = [
        "FEEDBACK_SHARE_NOT_FOUND": .shareNotFound,
        "INTERVIEW_SESSION_NOT_FOUND": .sessionNotFound,
        "FEEDBACK_SHARE_ALREADY_EXISTS": .alreadyExists,
        "INVALID_SHARE_STATUS": .invalidStatusTransition,
        "LOGIN_EXPIRED": .sessionExpired,
        "TOKEN_EXPIRED": .sessionExpired,
        "INVALID_TOKEN": .sessionExpired
    ]

    static let axesCodes: Set<String> = ["EMPTY_ATTITUDE_AXES", "TOO_MANY_ATTITUDE_AXES", "INVALID_ATTITUDE_AXIS"]

    init(mapping error: any Error) {
        switch error {
        case let error as FeedbackShareError:
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
        } else if Self.axesCodes.contains(error.code) {
            self = .invalidAxes(message: error.message)
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
