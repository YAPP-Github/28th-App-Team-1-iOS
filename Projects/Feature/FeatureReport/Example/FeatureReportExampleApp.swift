//
//  FeatureReportExampleApp.swift
//  FeatureReportExample
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainFeedbackShareInterface
import DomainInterviewReportInterface
import DomainInterviewReportTesting
import FeatureReportImplementation
import SwiftUI

/// 리포트 단독 데모 앱. AppFeature 에 아직 진입 경로가 없어(면접 진행 Part 2 미구현)
/// 여기서 fixture 를 주입해 화면 분기를 돌린다 — 정의서 §11-7 선행 조건.
@main
struct FeatureReportExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ReportView(
                store: Store(initialState: ReportFeature.State(sessionId: 1)) {
                    ReportFeature()
                } withDependencies: {
                    // 다른 분기를 보려면 .generating / .insufficientAnalysis / .withRedFlags 로 바꾼다.
                    $0.interviewReportClient = InterviewReportClient(
                        report: { _ in InterviewReportFixtures.ready }
                    )
                    // Example 은 Domain Implementation 을 link 하지 않아 liveValue 가 없다 —
                    // 지인 피드백 링크 생성은 고정 토큰으로 대체한다.
                    $0.feedbackShareClient = .previewValue
                    // previewValue 의 `status` 는 ACTIVE 링크를 줘서 진입 회수가 걸린다(항목 잠김 판) —
                    // 항목을 고르는 화면부터 보려면 «링크 없음» 으로 둔다. 회수 판을 보려면 이 줄을 지운다.
                    $0.feedbackShareClient.status = { _ in throw FeedbackShareError.shareNotFound }
                }
            )
        }
    }
}
