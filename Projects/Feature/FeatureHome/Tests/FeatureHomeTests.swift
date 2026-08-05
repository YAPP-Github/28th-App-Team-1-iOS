//
//  FeatureHomeTests.swift
//  FeatureHomeTests
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainPortfolioInterface
import DomainUserInterface
import Foundation
import Testing

@testable import FeatureHomeImplementation

@MainActor
struct HomeEntryLoadTests {
    private static func profile(name: String? = "재원", remaining: Int = 3) -> UserProfile {
        UserProfile(
            userId: UUID(uuidString: "00000000-0000-0000-0000-0000000000a1")!,
            name: name,
            email: nil,
            provider: "KAKAO",
            jobRole: "BACKEND",
            jobRoleLabel: "백엔드",
            careerYears: 3,
            remainingTicketCount: remaining
        )
    }

    private static func portfolio(status: PortfolioProcessingStatus = .ready) -> Portfolio {
        Portfolio(
            portfolioId: UUID(uuidString: "00000000-0000-0000-0000-0000000000a2")!,
            fileName: "포트폴리오.pdf",
            fileSize: 3_355_443,
            pageCount: 12,
            status: status,
            uploadedAt: Date(timeIntervalSince1970: 1_785_456_000)
        )
    }

    @Test("홈 진입은 프로필·포폴을 함께 싣고 면접 시작 변형을 «재사용» 으로 바꾼다")
    func entryLoadFillsNameRemainingAndPortfolio() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 2) }
            $0.portfolioClient.list = { [Self.portfolio()] }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.remainingChances = 2
            $0.startInterview.portfolio = StartInterviewFeature.Portfolio(
                fileName: "포트폴리오.pdf",
                uploadedAt: Date(timeIntervalSince1970: 1_785_456_000),
                byteCount: 3_355_443
            )
            $0.startInterview.variant = .hasPortfolio
        }
        // 목록은 성공했으니 이어서 온다 — 빈 배열이라 기록 없음(phase 는 `.default` 그대로).
        await store.receive(\.inner.reportsLoaded)
    }

    @Test("포폴 로드가 실패해도 프로필 값은 그대로 반영된다")
    func portfolioFailureKeepsProfileValues() async {
        struct LoadFailure: Error {}
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 1) }
            $0.portfolioClient.list = { throw LoadFailure() }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.remainingChances = 1
            // 포폴은 «모른다» 라서 직전 값을 유지한다 — nil 로 지우면 없는 것처럼 보인다.
            $0.startInterview.variant = .first
        }
        await store.receive(\.inner.reportsLoaded)
    }

    @Test("프로필 로드가 실패하면 소진이 아니라 «모른다» 로 둔다")
    func profileFailureIsNotExhausted() async {
        struct LoadFailure: Error {}
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { throw LoadFailure() }
            $0.portfolioClient.list = { [] }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear))
        // 잔여는 nil 그대로 — 0 으로 떨어뜨리면 «무료 횟수를 모두 사용했어요» 가 떠서
        // 시작 경로가 [홈으로] 하나로 막힌다. 변형도 초기값 `.first` 에서 안 움직인다.
        await store.receive(\.inner.entryLoaded)
        await store.receive(\.inner.reportsLoaded)
    }

    @Test("잔여 0 이면 포폴이 있어도 소진 변형이 이긴다")
    func exhaustedWinsOverPortfolio() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 0) }
            $0.portfolioClient.list = { [Self.portfolio()] }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.portfolio = StartInterviewFeature.Portfolio(
                fileName: "포트폴리오.pdf",
                uploadedAt: Date(timeIntervalSince1970: 1_785_456_000),
                byteCount: 3_355_443
            )
            $0.startInterview.variant = .exhausted
        }
        await store.receive(\.inner.reportsLoaded)
    }

    @Test("처리 중(PROCESSING) 포폴은 재사용 카드에 걸지 않는다")
    func processingPortfolioIsNotReusable() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 3) }
            $0.portfolioClient.list = { [Self.portfolio(status: .processing)] }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.remainingChances = 3
            $0.startInterview.variant = .first
        }
        await store.receive(\.inner.reportsLoaded)
    }

    @Test("이름이 비어 오면 앞서 그리던 이름을 지우지 않는다")
    func emptyNameKeepsPreviousName() async {
        let store = TestStore(initialState: HomeFeature.State(userName: "재원")) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(name: nil, remaining: 3) }
            $0.portfolioClient.list = { [] }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.startInterview.remainingChances = 3
        }
        await store.receive(\.inner.reportsLoaded)
    }
}

@MainActor
struct HomeReportListTests {
    /// 2026-07-31·07-28 KST 00:00 — 고정값이라 테스트가 날짜에 흔들리지 않는다.
    private static let july31 = Date(timeIntervalSince1970: 1_785_423_600)
    private static let july28 = Date(timeIntervalSince1970: 1_785_164_400)

    private static func summary(
        sessionId: Int,
        interviewedAt: Date,
        jobTypeLabel: String? = "백엔드 개발자",
        careerYears: Int? = 3
    ) -> InterviewReportSummary {
        InterviewReportSummary(
            sessionId: sessionId,
            jobType: "BACKEND",
            jobTypeLabel: jobTypeLabel,
            careerYears: careerYears,
            interviewedAt: interviewedAt,
            portfolioFileName: "포트폴리오.pdf",
            portfolioDeleted: false,
            jdUrl: nil,
            reportStatus: .ready,
            feedbackAvailable: false
        )
    }

    /// 목록만 보는 테스트라 프로필·포폴은 실패시켜 `entryLoaded` 의 상태 변화를 없앤다.
    private static func store(reports: @escaping @Sendable () async throws -> [InterviewReportSummary])
        -> TestStoreOf<HomeFeature> {
        struct LoadFailure: Error {}
        return TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { throw LoadFailure() }
            $0.portfolioClient.list = { throw LoadFailure() }
            $0.interviewClient.reportList = reports
        }
    }

    @Test("기록 리스트는 최신순 행으로 바뀌고 맨 위 행이 펼쳐진다")
    func reportsLoadedBuildsRowsNewestFirst() async {
        let store = Self.store {
            // 응답 순서를 일부러 뒤집어 둔다 — 정렬은 서버가 아니라 리듀서 책임이다.
            [Self.summary(sessionId: 9, interviewedAt: Self.july28),
             Self.summary(sessionId: 12, interviewedAt: Self.july31)]
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded)
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 12, dateText: "7월 31일 금", title: "백엔드 개발자 · 3년차 면접"),
                HomeFeature.Report(id: 9, dateText: "7월 28일 화", title: "백엔드 개발자 · 3년차 면접")
            ]
            $0.expandedReportID = 12
            $0.phase = .report(.recent)
        }
    }

    @Test("직군·연차가 없으면 제목에서 그 조각만 빠진다")
    func titleDropsMissingPieces() async {
        let store = Self.store {
            [Self.summary(sessionId: 1, interviewedAt: Self.july31, jobTypeLabel: nil, careerYears: 0),
             Self.summary(sessionId: 2, interviewedAt: Self.july28, jobTypeLabel: nil, careerYears: nil)]
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded)
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 1, dateText: "7월 31일 금", title: "신입 면접"),
                // 조각이 다 없으면 «면접» 한 단어만 남지 않게 «면접 리포트» 로 떨어진다.
                HomeFeature.Report(id: 2, dateText: "7월 28일 화", title: "면접 리포트")
            ]
            $0.expandedReportID = 1
            $0.phase = .report(.recent)
        }
    }

    @Test("목록 로드가 실패하면 앞서 그리던 목록을 지우지 않는다")
    func reportListFailureKeepsRows() async {
        struct LoadFailure: Error {}
        let existing = HomeFeature.Report(id: 3, dateText: "7월 11일 월", title: "백엔드 개발자 · 3년차 면접")
        let store = TestStore(initialState: HomeFeature.State(phase: .report(.returning), reports: [existing])) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { throw LoadFailure() }
            $0.portfolioClient.list = { throw LoadFailure() }
            $0.interviewClient.reportList = { throw LoadFailure() }
        }

        await store.send(.view(.onAppear))
        // `reportsLoaded` 자체가 오지 않는다 — 빈 배열로 뭉개면 기록이 있는 사용자의 시트가 비어 버린다.
        await store.receive(\.inner.entryLoaded)
    }

    @Test("기록이 없으면 phase 가 기본으로 돌아가고 확장 자리도 풀린다")
    func emptyReportsFallsBackToDefaultPhase() async {
        struct LoadFailure: Error {}
        var initial = HomeFeature.State(
            phase: .report(.returning),
            reports: [HomeFeature.Report(id: 3, dateText: "7월 11일 월", title: "백엔드 개발자 · 3년차 면접")]
        )
        initial.sheetDetent = .expanded
        let store = TestStore(initialState: initial) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { throw LoadFailure() }
            $0.portfolioClient.list = { throw LoadFailure() }
            $0.interviewClient.reportList = { [] }
        }

        await store.send(.view(.onAppear)) {
            // onAppear 가 시트를 기본 자리로 되돌린다 — 목록 판정보다 먼저다.
            $0.sheetDetent = .report
        }
        await store.receive(\.inner.entryLoaded)
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = []
            $0.expandedReportID = nil
            $0.phase = .default
        }
    }

    @Test("[레포트 보기] 는 세션 id 를 실어 부모에게 올린다")
    func reportTapDelegatesSessionId() async {
        let store = TestStore(
            initialState: HomeFeature.State(
                phase: .report(.recent),
                reports: [HomeFeature.Report(id: 12, dateText: "7월 31일 금", title: "백엔드 개발자 · 3년차 면접")]
            )
        ) {
            HomeFeature()
        }

        await store.send(.view(.userTappedReport(id: 12)))
        await store.receive(\.delegate.reportDetailRequested, 12)
    }
}
