//
//  FeatureHomeExampleApp.swift
//  FeatureHomeExample
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainUserInterface
import FeatureHomeImplementation
import Foundation
import SwiftUI

@main
struct FeatureHomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            // 실전(AppView)과 같은 조건 — 로고 내비바는 시스템 바 기반이라 스택 밖에선 안 그려진다.
            NavigationStack {
                HomeView(
                    store: Store(initialState: HomeFeature.State()) {
                        HomeFeature()
                    } withDependencies: {
                        // Example 은 Implementation 을 link 하지 않는다 — 진입 로드 2종을 가짜로 채워
                        // 네트워크 없이 홈을 돈다(안 채우면 liveValue 부재로 unimplemented 트랩).
                        $0.userClient.profile = { Self.profile }
                        $0.interviewClient.reportList = { Self.reports }
                        // 진행 중 세션 없음 — 기본은 «처음» 변형이다.
                        // 진행 중 시연은 이 줄을 아래로 바꾼다(2:12 녹화 → 5:48 남음 → 질문 3개):
                        // $0.heldSessionStore = .inMemory(initial: HeldSession(sessionId: 1, recordedSeconds: 132))
                        $0.heldSessionStore = .inMemory()
                    }
                )
            }
        }
    }

    /// 가짜 프로필 — 잔여 2회로 «소진 아님» 분기를 탄다.
    private static let profile = UserProfile(
        userId: UUID(uuidString: "00000000-0000-0000-0000-0000000000e1")!,
        name: "재원",
        email: "hilit@kakao.com",
        provider: "KAKAO",
        jobRole: "BACKEND",
        jobRoleLabel: "백엔드",
        careerYears: 3,
        remainingTicketCount: 2
    )

    /// 가짜 기록 — `ReportStatus` 4종을 한 건씩 넣어 행 규칙을 한 화면에서 본다.
    /// READY·INSUFFICIENT_ANALYSIS 는 같은 행([>] 로 상세 진입), FAILED 는 상세 없이 안내 문구가 붙은 행,
    /// GENERATING 은 `Report.init?(summary:)` 가 nil 로 떨궈 **행이 안 그려진다** — 그려지는 건 3행이다.
    /// `title` 없는 13번은 스냅샷(직군·연차) 제목으로 떨어져 두 제목 갈래를 같이 본다.
    /// 빈 배열로 바꾸면 기록 없는 `HomeDefault` 를 볼 수 있다.
    private static let reports: [InterviewReportSummary] = [
        report(
            sessionId: 11,
            interviewedAt: Date(timeIntervalSince1970: 1_783_728_000),
            status: .ready,
            title: "캐시 도입 결정의 이유와 한계까지 설명했어요"
        ),
        report(sessionId: 12, interviewedAt: Date(timeIntervalSince1970: 1_783_641_600), status: .generating),
        report(sessionId: 13, interviewedAt: Date(timeIntervalSince1970: 1_783_555_200), status: .insufficientAnalysis),
        report(sessionId: 14, interviewedAt: Date(timeIntervalSince1970: 1_783_468_800), status: .failed)
    ]

    private static func report(
        sessionId: Int,
        interviewedAt: Date,
        status: ReportStatus,
        title: String? = nil
    ) -> InterviewReportSummary {
        InterviewReportSummary(
            sessionId: sessionId,
            jobType: "BACKEND",
            jobTypeLabel: "백엔드 개발자",
            careerYears: 3,
            title: title,
            interviewedAt: interviewedAt,
            portfolioFileName: "포트폴리오.pdf",
            portfolioDeleted: false,
            jdUrl: nil,
            reportStatus: status,
            feedbackAvailable: false
        )
    }
}
