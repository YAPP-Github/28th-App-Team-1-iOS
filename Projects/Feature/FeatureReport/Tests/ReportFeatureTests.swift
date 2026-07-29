//
//  ReportFeatureTests.swift
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

/// 코디네이터 라우팅 — 메인이 허브라 화면들이 한 줄로 이어지지 않는 것을 고정한다 (정의서 §1-1).
@MainActor
struct ReportFeatureTests {
    private func loadedState() -> ReportFeature.State {
        var state = ReportFeature.State(sessionId: 1)
        state.main.report = InterviewReportFixtures.ready
        state.main.loadState = .loaded
        return state
    }

    @Test("영상 다시보기 → 플레이어 push (재생 가능한 영상이 있을 때만)")
    func videoRequestPushesPlayer() async {
        let store = TestStore(initialState: loadedState()) { ReportFeature() }

        await store.send(.main(.view(.userTappedWatchVideo)))
        await store.receive(\.main.delegate.videoRequested) {
            $0.path[id: 0] = .videoPlayer(ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                startAt: nil,
                cards: InterviewReportFixtures.ready.cards ?? []
            ))
        }
    }

    @Test("영상이 만료면 push 하지 않는다")
    func expiredVideoDoesNotPush() async {
        var state = ReportFeature.State(sessionId: 1)
        state.main.report = InterviewReportFixtures.insufficientAnalysis
        state.main.loadState = .loaded
        let store = TestStore(initialState: state) { ReportFeature() }

        await store.send(.main(.view(.userTappedWatchVideo)))
        await store.receive(\.main.delegate.videoRequested)
        #expect(store.state.path.isEmpty)
    }

    @Test("지인 피드백은 영상을 거치지 않고 메인에서 바로 push 된다")
    func peerFeedbackPushesDirectly() async {
        let store = TestStore(initialState: loadedState()) { ReportFeature() }

        await store.send(.main(.view(.userTappedPeerFeedback)))
        await store.receive(\.main.delegate.peerFeedbackRequested) {
            $0.path[id: 0] = .peerFeedback(ReportPeerFeedbackFeature.State(sessionId: 1))
        }
    }

    @Test("뒤로 → 스택 pop")
    func backPopsStack() async {
        var state = loadedState()
        state.path.append(.peerFeedback(ReportPeerFeedbackFeature.State(sessionId: 1)))
        let store = TestStore(initialState: state) { ReportFeature() }

        await store.send(.path(.element(id: 0, action: .peerFeedback(.view(.userTappedBack)))))
        await store.receive(\.path[id: 0].peerFeedback.delegate.backRequested) {
            $0.path = StackState()
        }
    }

    @Test("이탈(X)·다시 연습하기는 부모로 전파된다")
    func closeAndRetryPropagate() async {
        let store = TestStore(initialState: loadedState()) { ReportFeature() }

        await store.send(.main(.view(.userTappedClose)))
        await store.receive(\.main.delegate.closeRequested)
        await store.receive(\.delegate.closeRequested)

        await store.send(.main(.view(.userTappedRetry)))
        await store.receive(\.main.delegate.retryRequested)
        await store.receive(\.delegate.retryRequested)
    }
}
