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
                transcript: "문장",
                span: HighlightSpan(startIndex: 0, endIndex: 2, tone: "GOOD", analysis: nil),
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

    @Test("질문 탭은 선택 위치만 바꾸고, 범위를 벗어난 탭은 무시한다")
    func questionTabSelectsCard() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.ready }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.ready
            $0.loadState = .loaded
        }

        await store.send(.view(.userTappedQuestionTab(1))) {
            $0.selectedCardIndex = 1
        }
        await store.send(.view(.userTappedQuestionTab(99)))
        #expect(store.state.selectedCard == InterviewReportFixtures.improveCard)
    }

    @Test("카드가 줄면 선택 위치를 처음으로 되돌린다")
    func selectionResetsWhenCardsShrink() async {
        let clock = TestClock()
        let responses = LockIsolated([InterviewReportFixtures.ready, InterviewReportFixtures.lowResolutionOnly])
        let store = store(report: { _ in responses.withValue { $0.removeFirst() } }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.ready
            $0.loadState = .loaded
        }
        await store.send(.view(.userTappedQuestionTab(1))) {
            $0.selectedCardIndex = 1
        }

        // 카드가 1장뿐인 응답이 다시 들어오면 선택 위치가 범위를 벗어난다.
        await store.send(.inner(.reportLoaded(InterviewReportFixtures.lowResolutionOnly))) {
            $0.report = InterviewReportFixtures.lowResolutionOnly
            $0.selectedCardIndex = 0
        }
    }

    @Test("레드플래그 느낌표는 툴팁을 토글한다")
    func redFlagInfoTogglesTooltip() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.withRedFlags }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.withRedFlags
            $0.loadState = .loaded
        }
        #expect(store.state.hasRedFlagNotices)

        // 시안이 느낌표·툴팁을 함께 띄우므로 기본이 펼침이다 — 첫 탭이 접는 쪽이고,
        // 이 단정이 통과하는 것 자체가 기본값이 true 임을 확인한다.
        await store.send(.view(.userTappedRedFlagInfo)) { $0.isRedFlagTooltipVisible = false }
        await store.send(.view(.userTappedRedFlagInfo)) { $0.isRedFlagTooltipVisible = true }
    }

    @Test("지인을 바꾸면 펼쳐 둔 코멘트를 접는다")
    func guestTabResetsExpandedComments() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.withGuestFeedback }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.withGuestFeedback
            $0.loadState = .loaded
        }
        #expect(store.state.hasGuestFeedback)

        await store.send(.view(.userTappedAttitudeComment(axisCode: "EXPRESSION"))) {
            $0.expandedCommentAxes = ["EXPRESSION"]
        }
        await store.send(.view(.userTappedGuestTab(1))) {
            $0.selectedGuestIndex = 1
            $0.expandedCommentAxes = []
        }
        // 범위 밖 탭은 무시한다.
        await store.send(.view(.userTappedGuestTab(99)))
        #expect(store.state.selectedGuest == InterviewReportFixtures.secondGuest)
    }

    @Test("태도 코멘트는 항목별로 펼치고 접는다")
    func attitudeCommentToggles() async {
        let clock = TestClock()
        let store = store(report: { _ in InterviewReportFixtures.withGuestFeedback }, clock: clock)

        await store.send(.view(.onAppear))
        await store.receive(\.inner.reportLoaded) {
            $0.report = InterviewReportFixtures.withGuestFeedback
            $0.loadState = .loaded
        }

        await store.send(.view(.userTappedAttitudeComment(axisCode: "GAZE"))) {
            $0.expandedCommentAxes = ["GAZE"]
        }
        await store.send(.view(.userTappedAttitudeComment(axisCode: "VOICE"))) {
            $0.expandedCommentAxes = ["GAZE", "VOICE"]
        }
        await store.send(.view(.userTappedAttitudeComment(axisCode: "GAZE"))) {
            $0.expandedCommentAxes = ["VOICE"]
        }
    }

    @Test("폴링 타임아웃 후 수동 재시도가 폴링을 되살린다")
    func reloadRestartsAfterPollTimeout() async {
        let clock = TestClock()
        let responses = LockIsolated([InterviewReportFixtures.generating, InterviewReportFixtures.ready])
        // 상한을 소진한 상태에서 시작한다.
        var state = ReportMainFeature.State(sessionId: 1)
        state.pollTickCount = ReportMainFeature.pollLimit
        state.loadState = .pollTimedOut
        let store = TestStore(initialState: state) {
            ReportMainFeature()
        } withDependencies: {
            $0.interviewReportClient = InterviewReportClient(
                report: { _ in responses.withValue { $0.removeFirst() } }
            )
            $0.continuousClock = clock
        }

        await store.send(.view(.userTappedReload)) {
            $0.pollTickCount = 0
            $0.loadState = .loading
        }
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

    @Test("지인 피드백이 없으면 요청 카드를 보여준다")
    func noGuestFeedbackShowsRequestCard() {
        var state = ReportMainFeature.State(sessionId: 1)
        state.report = InterviewReportFixtures.ready   // guestFeedback == nil

        #expect(!state.hasGuestFeedback)
        #expect(state.guestParticipantCount == 0)
        #expect(state.selectedGuest == nil)
    }
}
