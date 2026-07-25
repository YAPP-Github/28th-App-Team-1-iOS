//
//  ReportFeatureTests.swift
//  FeatureReportTests
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import Testing

@testable import FeatureReportImplementation

@MainActor
struct ReportFeatureTests {
    @Test("메인 계속 → 영상 플레이어 push (임시 선형 플로우)")
    func mainContinuePushesVideoPlayer() async {
        let store = TestStore(initialState: ReportFeature.State()) {
            ReportFeature()
        }

        await store.send(.main(.view(.userTappedContinue)))
        await store.receive(\.main.delegate.continueRequested) {
            $0.path[id: 0] = .videoPlayer(ReportVideoPlayerFeature.State())
        }
    }

    @Test("영상 플레이어 계속 → 피드백 push, 피드백 계속 → 최종 push")
    func linearFlowPushesFeedbackThenFinal() async {
        var state = ReportFeature.State()
        state.path.append(.videoPlayer(ReportVideoPlayerFeature.State()))
        let store = TestStore(initialState: state) {
            ReportFeature()
        }

        await store.send(.path(.element(id: 0, action: .videoPlayer(.view(.userTappedContinue)))))
        await store.receive(\.path[id: 0].videoPlayer.delegate.continueRequested) {
            $0.path[id: 1] = .peerFeedback(ReportPeerFeedbackFeature.State())
        }

        await store.send(.path(.element(id: 1, action: .peerFeedback(.view(.userTappedContinue)))))
        await store.receive(\.path[id: 1].peerFeedback.delegate.continueRequested) {
            $0.path[id: 2] = .final(ReportFinalFeature.State())
        }
    }

    @Test("최종 완료 → finished 위임 (전환은 부모 몫)")
    func finalContinueDelegatesFinished() async {
        var state = ReportFeature.State()
        state.path.append(.final(ReportFinalFeature.State()))
        let store = TestStore(initialState: state) {
            ReportFeature()
        }

        await store.send(.path(.element(id: 0, action: .final(.view(.userTappedContinue)))))
        await store.receive(\.path[id: 0].final.delegate.continueRequested)
        await store.receive(\.delegate.finished)
    }

    @Test("뒤로 → 스택 pop")
    func backPopsStack() async {
        var state = ReportFeature.State()
        state.path.append(.videoPlayer(ReportVideoPlayerFeature.State()))
        let store = TestStore(initialState: state) {
            ReportFeature()
        }

        await store.send(.path(.element(id: 0, action: .videoPlayer(.view(.userTappedBack)))))
        await store.receive(\.path[id: 0].videoPlayer.delegate.backRequested) {
            $0.path = StackState()
        }
    }

    @Test("메인 X → closeRequested 위임 (dismiss 는 부모 몫)")
    func mainClosePropagates() async {
        let store = TestStore(initialState: ReportFeature.State()) {
            ReportFeature()
        }

        await store.send(.main(.view(.userTappedClose)))
        await store.receive(\.main.delegate.closeRequested)
        await store.receive(\.delegate.closeRequested)
    }
}
