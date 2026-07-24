//
//  GuestFeedbackClientLive.swift
//  DomainGuestFeedbackImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainGuestFeedbackInterface
import Foundation

// @lat: [[api#Guest Feedback]]
// depends-on: [[domain.map#네트워킹 인프라]]
// 무인증 API — Bearer 를 붙이는 AuthorizedNetworkClient 가 아니라 NetworkClient 를 직접 쓴다.
extension GuestFeedbackClient: @retroactive DependencyKey {
    public static var liveValue: GuestFeedbackClient {
        @Dependency(\.networkClient) var network

        return GuestFeedbackClient(
            entry: { token, deviceId in
                try await mappingGuestFeedbackError {
                    let request = NetworkRequest(
                        path: "/api/v1/feedback/guest/\(token)",
                        headers: ["Device-Id": deviceId]
                    )
                    return try await network.api(request)
                }
            },
            submit: { token, deviceId, submission in
                try await mappingGuestFeedbackError {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/feedback/guest/\(token)/submissions",
                        headers: ["Device-Id": deviceId],
                        body: submission
                    )
                    return try await network.api(request)
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(GuestFeedbackError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingGuestFeedbackError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw GuestFeedbackError(mapping: error)
    }
}

private extension GuestFeedbackError {
    /// 서버 에러 코드 → 고정 케이스. 제출 검증군(서버 문구 노출)은 `validationCodes` 로 분리.
    static let serverCodeMap: [String: GuestFeedbackError] = [
        "FEEDBACK_SHARE_TOKEN_NOT_FOUND": .tokenNotFound,
        "FEEDBACK_SHARE_CLOSED": .shareClosed,
        "FEEDBACK_CAPACITY_FULL": .capacityFull,
        "FEEDBACK_ALREADY_SUBMITTED": .alreadySubmitted
    ]

    static let validationCodes: Set<String> = ["INCOMPLETE_RATINGS", "INVALID_RATING_LEVEL", "MISSING_DEVICE_ID"]

    init(mapping error: any Error) {
        switch error {
        case let error as GuestFeedbackError:
            self = error
        case let error as ServerError:
            self.init(serverError: error)
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
