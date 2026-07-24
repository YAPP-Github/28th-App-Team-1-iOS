//
//  InterviewReportClientLive.swift
//  DomainInterviewReportImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewReportInterface
import Foundation

// @lat: [[api#Interview Report]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension InterviewReportClient: @retroactive DependencyKey {
    public static var liveValue: InterviewReportClient {
        @Dependency(\.authorizedNetworkClient) var network

        return InterviewReportClient(
            report: { sessionId in
                try await mappingInterviewReportError {
                    try await network.api(
                        NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/report")
                    )
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(InterviewReportError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingInterviewReportError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw InterviewReportError(mapping: error)
    }
}

private extension InterviewReportError {
    /// 서버 에러 코드 → 고정 케이스 (Report 는 문구 노출형 검증군이 없다 — 전부 고정 매핑).
    static let serverCodeMap: [String: InterviewReportError] = [
        "INTERVIEW_SESSION_NOT_FOUND": .sessionNotFound,
        "INTERVIEW_REPORT_NOT_FOUND": .reportNotFound,
        "LOGIN_EXPIRED": .sessionExpired,
        "TOKEN_EXPIRED": .sessionExpired,
        "INVALID_TOKEN": .sessionExpired
    ]

    init(mapping error: any Error) {
        switch error {
        case let error as InterviewReportError:
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
