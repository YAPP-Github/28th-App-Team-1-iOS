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
            $0.portfolioClient.list = { PortfolioList(portfolios: [Self.portfolio()]) }
            $0.interviewClient.reportList = { [] }
        }

        // 두 로드(프로필·포폴 / 기록 목록)는 별개 effect 라 해소 순서가 비결정이다 — 값만 고정한다.
        store.exhaustivity = .off
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

        // 두 로드(프로필·포폴 / 기록 목록)는 별개 effect 라 해소 순서가 비결정이다 — 값만 고정한다.
        store.exhaustivity = .off
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
            $0.portfolioClient.list = { PortfolioList(portfolios: []) }
            $0.interviewClient.reportList = { [] }
        }

        // 두 로드(프로필·포폴 / 기록 목록)는 별개 effect 라 해소 순서가 비결정이다 — 값만 고정한다.
        store.exhaustivity = .off
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
            $0.portfolioClient.list = { PortfolioList(portfolios: [Self.portfolio()]) }
            $0.interviewClient.reportList = { [] }
        }

        // 두 로드(프로필·포폴 / 기록 목록)는 별개 effect 라 해소 순서가 비결정이다 — 값만 고정한다.
        store.exhaustivity = .off
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
            $0.portfolioClient.list = { PortfolioList(portfolios: [Self.portfolio(status: .processing)]) }
            $0.interviewClient.reportList = { [] }
        }

        // 두 로드(프로필·포폴 / 기록 목록)는 별개 effect 라 해소 순서가 비결정이다 — 값만 고정한다.
        store.exhaustivity = .off
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
            $0.portfolioClient.list = { PortfolioList(portfolios: []) }
            $0.interviewClient.reportList = { [] }
        }

        // 두 로드(프로필·포폴 / 기록 목록)는 별개 effect 라 해소 순서가 비결정이다 — 값만 고정한다.
        store.exhaustivity = .off
        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.startInterview.remainingChances = 3
        }
        await store.receive(\.inner.reportsLoaded)
    }
}

/// 기록 목록만 보는 테스트에서 프로필·포폴 로드를 죽여 두는 용도.
private struct ProfileUnavailable: Error {}

@MainActor
struct HomeReportListTests {
    /// 2026-07-11(토) 09:00 KST — 표시 포맷 «7월 11일 토» 검증용 고정 시각.
    private static let interviewedAt = Date(timeIntervalSince1970: 1_783_728_000)

    private static func summary(
        sessionId: Int = 7,
        careerYears: Int? = 3,
        interviewedAt: Date = HomeReportListTests.interviewedAt,
        jobTypeLabel: String? = "백엔드 개발자",
        status: ReportStatus = .ready
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
            reportStatus: status,
            feedbackAvailable: false
        )
    }

    private static func store(
        initialState: HomeFeature.State = HomeFeature.State(),
        reportList: @escaping @Sendable () async throws -> [InterviewReportSummary]
    ) -> TestStore<HomeFeature.State, HomeFeature.Action> {
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { throw ProfileUnavailable() }
            $0.portfolioClient.list = { throw ProfileUnavailable() }
            $0.interviewClient.reportList = reportList
        }
        // 프로필·포폴 로드와 순서가 섞인다 — 목록 쪽 값만 고정한다.
        store.exhaustivity = .off
        return store
    }

    @Test("목록 응답은 세션 id·날짜·직군 스냅샷 행으로 들어오고 phase 가 report 로 바뀐다")
    func reportListFillsRows() async {
        let store = Self.store(reportList: { [Self.summary()] })

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 7, dateText: "7월 11일 토", title: "백엔드 개발자 · 3년차")
            ]
            $0.expandedReportIDs = [7]
            $0.phase = .report(.returning)
        }
    }

    @Test("응답 순서가 뒤집혀 와도 최신순으로 정렬해 맨 위 행을 펼친다")
    func reportListSortsNewestFirst() async {
        // 응답 순서를 일부러 뒤집어 둔다 — 정렬은 서버가 아니라 리듀서 책임이다.
        let older = Date(timeIntervalSince1970: 1_783_641_600)  // 7월 10일(금) 09:00 KST
        let store = Self.store(reportList: {
            [
                Self.summary(sessionId: 1, interviewedAt: older),
                Self.summary(sessionId: 2)
            ]
        })

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 2, dateText: "7월 11일 토", title: "백엔드 개발자 · 3년차"),
                HomeFeature.Report(id: 1, dateText: "7월 10일 금", title: "백엔드 개발자 · 3년차")
            ]
            $0.expandedReportIDs = [2]
            $0.phase = .report(.returning)
        }
    }

    @Test("생성 중 세션은 행에서 빠지고, 분석 부족은 READY·실패는 상태 문구 행으로 들어온다")
    func generatingReportsAreDropped() async {
        // 날짜를 하루씩 달리 둔다 — 최신순 정렬이 같은 날짜에서 흔들리지 않게(정렬 자체는 별도 테스트).
        let july10 = Date(timeIntervalSince1970: 1_783_641_600)
        let july9 = Date(timeIntervalSince1970: 1_783_555_200)
        let store = Self.store(reportList: {
            [
                Self.summary(sessionId: 1, status: .generating),
                Self.summary(sessionId: 2, interviewedAt: july10, status: .insufficientAnalysis),
                Self.summary(sessionId: 3, interviewedAt: july9, status: .failed)
            ]
        })

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 2, dateText: "7월 10일 금", title: "백엔드 개발자 · 3년차"),
                HomeFeature.Report(
                    id: 3,
                    dateText: "7월 9일 목",
                    title: "레포트 생성에 실패했어요",
                    subtitle: "이용권 횟수는 차감되지 않아요",
                    canOpenReport: false
                )
            ]
            $0.expandedReportIDs = [2]
            $0.phase = .report(.returning)
        }
    }

    @Test("전부 생성 중이면 목록이 비어 기본 상태로 떨어진다")
    func allGeneratingFallsBackToDefaultPhase() async {
        let store = Self.store(
            initialState: HomeFeature.State(phase: .report(.returning), reports: [
                HomeFeature.Report(id: 1, dateText: "7월 10일 금", title: "옛 행")
            ]),
            reportList: { [Self.summary(sessionId: 1, status: .generating)] }
        )

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = []
            $0.expandedReportIDs = []
            $0.phase = .default
        }
    }

    @Test("연차 표기는 온보딩 휠 규칙을 따른다 — 0 은 신입, 10 이상은 «10년 이상»")
    func careerTextFollowsWheelRule() async {
        let older = Date(timeIntervalSince1970: 1_783_641_600)  // 7월 10일(금) 09:00 KST
        let store = Self.store(reportList: {
            [
                Self.summary(sessionId: 1, careerYears: 0),
                Self.summary(sessionId: 2, careerYears: 12, interviewedAt: older)
            ]
        })

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 1, dateText: "7월 11일 토", title: "백엔드 개발자 · 신입"),
                HomeFeature.Report(id: 2, dateText: "7월 10일 금", title: "백엔드 개발자 · 10년 이상")
            ]
            $0.expandedReportIDs = [1]
            $0.phase = .report(.returning)
        }
    }

    @Test("직군·연차가 비어 오면 조각을 빼고 준비 완료 문구만 남긴다")
    func missingSnapshotFallsBackToReadyText() async {
        let store = Self.store(reportList: { [Self.summary(careerYears: nil, jobTypeLabel: nil)] })

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = [
                HomeFeature.Report(id: 7, dateText: "7월 11일 토", title: "면접 레포트가 준비됐어요")
            ]
            $0.expandedReportIDs = [7]
            $0.phase = .report(.returning)
        }
    }

    @Test("빈 목록은 기본 상태로 되돌리고 확장 자리를 접는다")
    func emptyListFallsBackToDefaultPhase() async {
        let store = Self.store(
            initialState: HomeFeature.State(phase: .report(.returning), reports: [
                HomeFeature.Report(id: 1, dateText: "7월 10일 금", title: "옛 행")
            ]),
            reportList: { [] }
        )

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportsLoaded) {
            $0.reports = []
            $0.expandedReportIDs = []
            $0.phase = .default
        }
    }

    @Test("목록 호출이 실패하면 앞서 그리던 목록을 지우지 않는다")
    func listFailureKeepsPreviousRows() async {
        struct LoadFailure: Error {}
        let previous = HomeFeature.Report(id: 1, dateText: "7월 10일 금", title: "옛 행")
        let store = Self.store(
            initialState: HomeFeature.State(phase: .report(.recent), reports: [previous]),
            reportList: { throw LoadFailure() }
        )

        await store.send(.view(.onAppear))
        // nil = «모른다» — 목록을 비우면 기록이 사라진 것처럼 보인다.
        await store.receive(\.inner.reportsLoaded)
        #expect(store.state.reports.elements == [previous])
        #expect(store.state.phase == .report(.recent))
    }
}

@MainActor
struct HomeReportExpansionTests {
    private static func report(_ id: Int) -> HomeFeature.Report {
        HomeFeature.Report(id: id, dateText: "7월 1\(id)일 토", title: "백엔드 개발자 · 3년차")
    }

    private static func store() -> TestStore<HomeFeature.State, HomeFeature.Action> {
        TestStore(
            initialState: HomeFeature.State(
                phase: .report(.returning),
                reports: [report(1), report(2), report(3)]
            )
        ) {
            HomeFeature()
        }
    }

    @Test("행 탭은 다른 행을 닫지 않는다 — 여러 행을 동시에 펼쳐 둔다")
    func rowsExpandIndependently() async {
        let store = Self.store()
        // 진입 시엔 최신 1개만 펼쳐져 있다.
        #expect(store.state.expandedReportIDs == [1])

        await store.send(.view(.userTappedReportRow(id: 2))) {
            $0.expandedReportIDs = [1, 2]
        }
        await store.send(.view(.userTappedReportRow(id: 3))) {
            $0.expandedReportIDs = [1, 2, 3]
        }
    }

    @Test("펼친 행을 다시 탭하면 그 행만 접힌다")
    func tappingExpandedRowCollapsesOnlyThatRow() async {
        let store = Self.store()
        await store.send(.view(.userTappedReportRow(id: 2))) {
            $0.expandedReportIDs = [1, 2]
        }
        await store.send(.view(.userTappedReportRow(id: 1))) {
            $0.expandedReportIDs = [2]
        }
    }

    @Test("[>] 탭은 세션 id 를 그대로 상세 진입 delegate 로 넘긴다")
    func detailButtonForwardsSessionID() async {
        let store = Self.store()
        await store.send(.view(.userTappedReport(id: 3)))
        await store.receive(\.delegate.reportDetailRequested)
    }
}
