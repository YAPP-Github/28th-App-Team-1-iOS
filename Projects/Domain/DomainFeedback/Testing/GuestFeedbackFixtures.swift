//
//  GuestFeedbackFixtures.swift
//  DomainFeedbackTesting
//
//  Created by 서정원 on 26/07/20.
//

import DomainFeedbackInterface
import Foundation

public extension AttitudeAxis {
    /// 서버 태도 5종 전체 (Rating.axis enum 미러).
    static let allFive: [AttitudeAxis] = [
        AttitudeAxis(code: "GAZE", displayName: "시선"),
        AttitudeAxis(code: "EXPRESSION", displayName: "표정"),
        AttitudeAxis(code: "POSTURE", displayName: "자세"),
        AttitudeAxis(code: "GESTURE", displayName: "손동작"),
        AttitudeAxis(code: "VOICE", displayName: "목소리")
    ]
}

public extension GuestFeedbackEntry {
    /// 시나리오별 엔트리 — 기본은 OPEN 해피패스(영상 없음).
    static func fixture(
        gate: GuestFeedbackGate = .open,
        requesterName: String? = "재원",
        axes: [AttitudeAxis] = AttitudeAxis.allFive,
        videoURL: URL? = nil,
        questionBoundaries: [QuestionBoundary] = [
            QuestionBoundary(turnLevel: 1, startAt: 0, questionText: "1분 자기소개 부탁드려요"),
            QuestionBoundary(turnLevel: 2, startAt: 42.5, questionText: "협업 갈등 경험을 말해 주세요")
        ],
        submissionOpen: Bool = true
    ) -> GuestFeedbackEntry {
        GuestFeedbackEntry(
            gate: gate,
            requesterName: requesterName,
            axes: axes,
            videoURL: videoURL,
            questionBoundaries: questionBoundaries,
            submissionOpen: submissionOpen
        )
    }
}

public extension GuestFeedbackClient {
    /// 다른 모듈의 테스트·Example 에서 주입하는 mock — enter 는 고정 엔트리, submit 은 성공(또는 지정 에러).
    static func mock(
        entry: GuestFeedbackEntry = .fixture(),
        submitError: GuestFeedbackError? = nil
    ) -> GuestFeedbackClient {
        GuestFeedbackClient(
            enter: { _ in entry },
            submit: { _, _ in
                if let submitError { throw submitError }
                return GuestSubmissionReceipt(submissionID: 1, submittedAt: Date(timeIntervalSince1970: 1_784_500_000))
            }
        )
    }
}
