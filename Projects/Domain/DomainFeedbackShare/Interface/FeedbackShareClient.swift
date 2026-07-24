//
//  FeedbackShareClient.swift
//  DomainFeedbackShareInterface
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 공유 링크 상태. 비공개 전환(PRIVATE)은 되돌릴 수 없다.
public enum FeedbackShareState: String, Decodable, Equatable, Sendable {
    case active = "ACTIVE"
    case invalidated = "INVALIDATED"
    case `private` = "PRIVATE"
}

/// 참여 현황 — R1 리포트의 지인 피드백 요청 상태 표시에 쓴다.
public struct FeedbackShareStatus: Decodable, Equatable, Sendable {
    /// 공유 토큰 — 클라이언트가 이 토큰으로 공유 딥링크를 조립한다.
    public let token: String
    public let status: FeedbackShareState
    /// 지정된 태도 항목 코드 (GAZE 등, 생성 후 잠김)
    public let axes: [String]?
    /// 제출한 지인 수 (참고치, 최대 4)
    public let submittedCount: Int?
    /// 영상 삭제 예정 시각
    public let videoExpiresAt: Date?
    /// 피드백 요청(최초 링크 생성) 시각
    public let requestedAt: Date?

    public init(
        token: String,
        status: FeedbackShareState,
        axes: [String]?,
        submittedCount: Int?,
        videoExpiresAt: Date?,
        requestedAt: Date?
    ) {
        self.token = token
        self.status = status
        self.axes = axes
        self.submittedCount = submittedCount
        self.videoExpiresAt = videoExpiresAt
        self.requestedAt = requestedAt
    }
}

/// 공유 링크 생성 응답. 최초 생성이 곧 '피드백 요청' 사건 — 영상 삭제 예정 시각이 +48h 연장된다.
public struct FeedbackShareCreated: Decodable, Equatable, Sendable {
    public let token: String

    public init(token: String) {
        self.token = token
    }
}

// MARK: - Client

/// 지인 피드백 공유 설정 API (D14 `/api/v1/feedback/sessions/**`, 사용자측·인증 필요).
/// 게스트측(무인증·토큰 진입)은 별도 도메인 — [[api#Guest Feedback]].
// @lat: [[api#Feedback Share]]
public struct FeedbackShareClient: Sendable {
    /// GET /feedback/sessions/{id}/share — 링크 상태·참여 현황.
    public var status: @Sendable (_ sessionId: Int) async throws -> FeedbackShareStatus
    /// POST /feedback/sessions/{id}/share — 링크 생성 + 태도 항목(1~5개, `Axis` 코드) 지정. 면접당 활성 링크 1개.
    public var create: @Sendable (_ sessionId: Int, _ axes: [String]) async throws -> FeedbackShareCreated
    /// PATCH /feedback/sessions/{id}/share — 비공개 전환 (되돌릴 수 없음, 기제출 피드백은 유지).
    public var makePrivate: @Sendable (_ sessionId: Int) async throws -> Void

    public init(
        status: @escaping @Sendable (_ sessionId: Int) async throws -> FeedbackShareStatus,
        create: @escaping @Sendable (_ sessionId: Int, _ axes: [String]) async throws -> FeedbackShareCreated,
        makePrivate: @escaping @Sendable (_ sessionId: Int) async throws -> Void
    ) {
        self.status = status
        self.create = create
        self.makePrivate = makePrivate
    }
}

extension FeedbackShareClient: TestDependencyKey {
    public static var testValue: FeedbackShareClient {
        FeedbackShareClient(
            status: unimplemented("FeedbackShareClient.status"),
            create: unimplemented("FeedbackShareClient.create"),
            makePrivate: unimplemented("FeedbackShareClient.makePrivate")
        )
    }

    public static var previewValue: FeedbackShareClient {
        FeedbackShareClient(
            status: { _ in
                FeedbackShareStatus(
                    token: "preview-token",
                    status: .active,
                    axes: ["GAZE", "EXPRESSION", "POSTURE", "GESTURE", "VOICE"],
                    submittedCount: 2,
                    videoExpiresAt: Date(timeIntervalSince1970: 1_782_172_800),
                    requestedAt: Date(timeIntervalSince1970: 1_782_000_000)
                )
            },
            create: { _, _ in FeedbackShareCreated(token: "preview-token") },
            makePrivate: { _ in }
        )
    }
}

public extension DependencyValues {
    var feedbackShareClient: FeedbackShareClient {
        get { self[FeedbackShareClient.self] }
        set { self[FeedbackShareClient.self] = newValue }
    }
}
