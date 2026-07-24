//
//  InterviewReportClientMock.swift
//  DomainInterviewReportTesting
//
//  Created by EunseoKim on 26/07/23.
//

import DomainInterviewReportInterface
import Foundation

public extension InterviewReportClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — READY 보고서를 그대로 돌려준다.
    static var mock: InterviewReportClient {
        InterviewReportClient(
            report: { _ in
                InterviewReport(
                    status: .ready,
                    headline: "mock 보고서",
                    redFlagNotices: nil,
                    video: nil,
                    cards: [],
                    guestFeedback: nil
                )
            }
        )
    }
}
