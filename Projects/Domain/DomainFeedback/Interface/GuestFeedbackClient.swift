//
//  GuestFeedbackClient.swift
//  DomainFeedbackInterface
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import Foundation

// @lat: [[feedback#Client 계약]]
// Feature 가 Guest Feedback 도메인에 접근하는 유일한 계약 — D14 Guest Feedback API([[api#Guest Feedback]]) 미러링.
// 무인증 API. Device-Id 헤더는 liveValue 가 내부에서 붙인다 — Feature 는 그 존재를 모른다.
public struct GuestFeedbackClient: Sendable {
    /// GET /api/v1/feedback/guest/{token} — 진입 + 게이트 판정. 최초 조회 시 서버가 영상 보관을 +7일 연장.
    public var enter: @Sendable (_ token: String) async throws -> GuestFeedbackEntry
    /// POST /api/v1/feedback/guest/{token}/submissions — 지정 항목 전부 필수. 첫 제출 시 +30일 연장.
    public var submit: @Sendable (_ token: String, GuestSubmission) async throws -> GuestSubmissionReceipt

    public init(
        enter: @escaping @Sendable (_ token: String) async throws -> GuestFeedbackEntry,
        submit: @escaping @Sendable (_ token: String, GuestSubmission) async throws -> GuestSubmissionReceipt
    ) {
        self.enter = enter
        self.submit = submit
    }
}

extension GuestFeedbackClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지.
    public static var testValue: GuestFeedbackClient {
        GuestFeedbackClient(
            enter: unimplemented("GuestFeedbackClient.enter"),
            submit: unimplemented("GuestFeedbackClient.submit")
        )
    }

    /// Preview 용 — 네트워크 없이 OPEN 게이트 해피패스를 그린다.
    public static var previewValue: GuestFeedbackClient {
        GuestFeedbackClient(
            enter: { _ in
                GuestFeedbackEntry(
                    gate: .open,
                    requesterName: "재원",
                    axes: [
                        AttitudeAxis(code: "GAZE", displayName: "시선"),
                        AttitudeAxis(code: "EXPRESSION", displayName: "표정"),
                        AttitudeAxis(code: "POSTURE", displayName: "자세"),
                        AttitudeAxis(code: "GESTURE", displayName: "손동작"),
                        AttitudeAxis(code: "VOICE", displayName: "목소리")
                    ],
                    videoURL: nil,
                    questionBoundaries: [
                        QuestionBoundary(turnLevel: 1, startAt: 0, questionText: "1분 자기소개 부탁드려요"),
                        QuestionBoundary(turnLevel: 2, startAt: 42.5, questionText: "협업 갈등 경험을 말해 주세요")
                    ],
                    submissionOpen: true
                )
            },
            submit: { _, _ in
                GuestSubmissionReceipt(submissionID: 1, submittedAt: Date(timeIntervalSince1970: 1_784_500_000))
            }
        )
    }
}

public extension DependencyValues {
    var guestFeedbackClient: GuestFeedbackClient {
        get { self[GuestFeedbackClient.self] }
        set { self[GuestFeedbackClient.self] = newValue }
    }
}
