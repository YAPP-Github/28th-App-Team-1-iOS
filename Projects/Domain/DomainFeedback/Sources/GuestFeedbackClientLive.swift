//
//  GuestFeedbackClientLive.swift
//  DomainFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainFeedbackInterface
import Foundation

// @lat: [[feedback#Client 계약]]
// depends-on: [[domain.map#네트워킹 인프라]] (무인증 API — AuthorizedNetworkClient 가 아니라 NetworkClient 를 쓴다)
extension GuestFeedbackClient: @retroactive DependencyKey {
    public static var liveValue: GuestFeedbackClient {
        @Dependency(\.networkClient) var network
        @Dependency(\.guestFeedbackLocalStore) var localStore

        // Device-Id 는 인프라 관심사(중복 제출 방지) — 여기서만 붙이고 Feature 에는 노출하지 않는다.
        @Sendable func deviceHeaders() -> [String: String] {
            ["Device-Id": localStore.deviceID()]
        }

        return GuestFeedbackClient(
            enter: { token in
                let request = NetworkRequest(
                    path: "/api/v1/feedback/guest/\(token)",
                    headers: deviceHeaders()
                )
                do {
                    return try await network.api(request, as: GuestFeedbackEntry.self)
                } catch {
                    throw GuestFeedbackError.promote(error)
                }
            },
            submit: { token, submission in
                let request = try NetworkRequest.json(
                    method: .post,
                    path: "/api/v1/feedback/guest/\(token)/submissions",
                    headers: deviceHeaders(),
                    body: SubmitBody(submission),
                    encoder: .api
                )
                do {
                    return try await network.api(request, as: GuestSubmissionReceipt.self)
                } catch {
                    throw GuestFeedbackError.promote(error)
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

/// GuestRating.axisCode → 서버 필드 `axis` 로 펼친다.
private struct SubmitBody: Encodable {
    struct RatingBody: Encodable {
        let axis: String
        let level: Int
        let comment: String?
    }

    let nickname: String?
    let ratings: [RatingBody]
    let overallFeedback: String?

    init(_ submission: GuestSubmission) {
        nickname = submission.nickname
        ratings = submission.ratings.map {
            RatingBody(axis: $0.axisCode, level: $0.level, comment: $0.comment)
        }
        overallFeedback = submission.overallFeedback
    }
}

private extension GuestFeedbackError {
    /// ServerError 코드 → 도메인 에러 승격 — 서버 코드 문자열이 Feature 로 새지 않는 유일한 변환 지점.
    /// ServerError 가 아니면(오프라인·취소 등) 원래 에러를 그대로 흘린다.
    static func promote(_ error: any Error) -> any Error {
        guard let serverError = error as? ServerError else { return error }
        switch serverError.code {
        case "FEEDBACK_SHARE_CLOSED": return GuestFeedbackError.closed
        case "FEEDBACK_CAPACITY_FULL": return GuestFeedbackError.capacityFull
        case "FEEDBACK_ALREADY_SUBMITTED": return GuestFeedbackError.alreadySubmitted
        case "FEEDBACK_SHARE_TOKEN_NOT_FOUND": return GuestFeedbackError.invalidToken
        case "INCOMPLETE_RATINGS", "INVALID_RATING_LEVEL", "MISSING_DEVICE_ID":
            return GuestFeedbackError.invalidSubmission
        default:
            return GuestFeedbackError.underlying(message: serverError.message)
        }
    }
}
