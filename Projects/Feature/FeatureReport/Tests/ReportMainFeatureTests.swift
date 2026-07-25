//
//  ReportMainFeatureTests.swift
//  FeatureReportTests
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import DomainInterviewReportTesting
import Foundation
import Testing

@testable import FeatureReportImplementation

@MainActor
struct ReportMainFeatureTests {
    private func store(
        report: @escaping @Sendable (Int) async throws -> InterviewReport,
        clock: TestClock<Duration>
    ) -> TestStore<ReportMainFeature.State, ReportMainFeature.Action> {
        TestStore(initialState: ReportMainFeature.State(sessionId: 1)) {
            ReportMainFeature()
        } withDependencies: {
            $0.interviewReportClient = InterviewReportClient(report: report)
            $0.continuousClock = clock
        }
    }

    @Test("채점 중이면 폴링하고 READY 에서 멈춘다")
    func pollsWhileGeneratingThenStops() async {
        let clock = TestClock()
        let responses = LockIsolated([InterviewReportFixtures.generating, InterviewReportFixtures.ready])
        let store = store(
            report: { _ in responses.withValue { $0.removeFirst() } },
            clock: clock
        )

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.generating
            $0.pollTickCount = 1
        }

        await clock.advance(by: ReportMainFeature.pollInterval)
        await store.receive(\.inner.pollTicked)
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.ready
            $0.loadState = .loaded
        }
    }

    @Test("보고서 미생성(404)은 에러가 아니라 폴링 대상이다")
    func reportNotFoundKeepsPolling() async {
        let clock = TestClock()
        let store = store(report: { _ in throw InterviewReportError.reportNotFound }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportFailed) {
            $0.pollTickCount = 1
            $0.loadState = .loading
        }

        await store.skipInFlightEffects()
    }

    @Test("폴링 상한을 넘으면 수동 재시도로 넘어가고 effect 가 멈춘다")
    func pollLimitEndsPolling() async {
        let clock = TestClock()
        var state = ReportMainFeature.State(sessionId: 1)
        state.pollTickCount = ReportMainFeature.pollLimit
        let store = TestStore(initialState: state) {
            ReportMainFeature()
        } withDependencies: {
            $0.interviewReportClient = InterviewReportClient(
                report: { _ in InterviewReportFixtures.generating }
            )
            $0.continuousClock = clock
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.generating
            $0.loadState = .pollTimedOut
        }
    }

    @Test("복구 불가 에러는 실패 상태로 끝낸다")
    func sessionNotFoundFails() async {
        let clock = TestClock()
        let store = store(report: { _ in throw InterviewReportError.sessionNotFound }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportFailed) {
            $0.loadState = .failed(.sessionNotFound)
        }
    }

    @Test("레드플래그 3건은 2건으로 잘린다")
    func redFlagNoticesAreTruncated() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.withRedFlags }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.withRedFlags
            $0.loadState = .loaded
        }
        #expect(store.state.visibleRedFlagNotices.count == 2)
    }

    @Test("만료·nil·형식오류 영상은 재생 대상이 아니다")
    func expiredVideoIsNotPlayable() {
        var state = ReportMainFeature.State(sessionId: 1)

        state.report = InterviewReportFixtures.insufficientAnalysis   // expired == true
        #expect(state.playableVideoURL == nil)

        state.report = InterviewReportFixtures.lowResolutionOnly      // video == nil
        #expect(state.playableVideoURL == nil)

        state.report = InterviewReportFixtures.ready
        #expect(state.playableVideoURL != nil)
    }

    @Test("하이라이트 탭은 시트를 올리고 톤을 타입으로 좁힌다")
    func highlightTapPresentsSheet() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.ready }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.ready
            $0.loadState = .loaded
        }

        await store.send(.view(.userTappedHighlight(cardIndex: 0, spanIndex: 0))) {
            $0.highlightDetail = ReportHighlightDetailFeature.State(
                context: HighlightContext(
                    card: InterviewReportFixtures.strongCard,
                    span: InterviewReportFixtures.strongCard.highlightSpans![0]
                )!,
                showsVideoJump: true
            )
        }
        #expect(store.state.highlightDetail?.context.tone == .good)
    }

    @Test("범위를 벗어난 인덱스는 시트를 올리지 않는다")
    func outOfRangeHighlightIsIgnored() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.ready }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.ready
            $0.loadState = .loaded
        }

        await store.send(.view(.userTappedHighlight(cardIndex: 99, spanIndex: 0)))
        await store.send(.view(.userTappedHighlight(cardIndex: 0, spanIndex: 99)))
    }

    @Test("해상도 낮음 카드는 탭 대상이 없다")
    func lowResolutionCardHasNoHighlight() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.lowResolutionOnly }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.lowResolutionOnly
            $0.loadState = .loaded
        }

        await store.send(.view(.userTappedHighlight(cardIndex: 0, spanIndex: 0)))
        #expect(store.state.cards[0].isLowResolution)
    }

    @Test("시트의 장면 이동 요청은 시트를 닫고 영상 요청으로 번역된다")
    func videoJumpClosesSheetAndRequestsVideo() async {
        var state = ReportMainFeature.State(sessionId: 1)
        state.report = InterviewReportFixtures.ready
        state.loadState = .loaded
        state.highlightDetail = ReportHighlightDetailFeature.State(
            context: HighlightContext(
                sentence: "문장",
                tone: .good,
                analysis: nil,
                evidenceAt: 12
            ),
            showsVideoJump: true
        )
        let store = TestStore(initialState: state) { ReportMainFeature() }

        await store.send(.highlightDetail(.presented(.view(.userTappedVideoJump))))
        await store.receive(\.highlightDetail.presented.delegate.videoJumpRequested) {
            $0.highlightDetail = nil
        }
        await store.receive(\.delegate.videoRequested)
    }
}
