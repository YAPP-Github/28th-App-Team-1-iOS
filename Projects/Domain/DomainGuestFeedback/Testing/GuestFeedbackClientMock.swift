//
//  GuestFeedbackClientMock.swift
//  DomainGuestFeedbackTesting
//
//  Created by EunseoKim on 26/07/23.
//

import DomainGuestFeedbackInterface
import Foundation

public extension GuestFeedbackClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — OPEN 게이트와 제출 성공을 돌려준다.
    static var mock: GuestFeedbackClient {
        GuestFeedbackClient(
            entry: { _, _ in
                GuestFeedbackEntry(
                    gate: .open,
                    requesterName: "히릿",
                    axes: [AttitudeAxis(code: "GAZE", displayName: "시선")],
                    videoUrl: nil,
                    questionBoundaries: [],
                    submissionOpen: true
                )
            },
            submit: { _, _, _ in
                GuestFeedbackReceipt(
                    submissionId: 1,
                    submittedAt: Date(timeIntervalSince1970: 1_782_000_000)
                )
            }
        )
    }
}
