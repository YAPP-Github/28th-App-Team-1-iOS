//
//  FeatureReportExampleApp.swift
//  FeatureReportExample
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
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
                }
            )
        }
    }
}
