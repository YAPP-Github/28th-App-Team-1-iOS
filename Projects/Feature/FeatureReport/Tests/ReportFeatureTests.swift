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
            // 대본 타임라인까지 함께 넘긴다 — 진행바 칸이 세션 전체 `script` 를 재료로 쓴다.
            $0.path[id: 0] = .videoPlayer(ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                startAt: nil,
                cards: InterviewReportFixtures.ready.cards ?? [],
                script: InterviewReportFixtures.ready.script ?? []
            ))
        }
    }

    /// 하이라이트 상세 시트를 열어 둔 메인.
    private func sheetOpenedState() -> ReportFeature.State {
        var state = loadedState()
        state.main.highlightDetail = Self.highlightDetail
        return state
    }

    private static let highlightDetail = ReportHighlightDetailFeature.State(
        context: HighlightContext(
            transcript: "문장",
            span: HighlightSpan(startIndex: 0, endIndex: 2, tone: "GOOD", analysis: nil),
            evidenceAt: 12
        ),
        showsVideoJump: true
    )

    @Test("시트 «영상 보러가기» 로 들어온 플레이어는 하단 «이전 화면으로 가기» 판이다")
    func sheetEntryPushesReturnablePlayer() async {
        let store = TestStore(initialState: sheetOpenedState()) { ReportFeature() }

        await store.send(.main(.highlightDetail(.presented(.view(.userTappedVideoJump)))))
        await store.receive(\.main.highlightDetail.presented.delegate.videoJumpRequested) {
            // 시트는 닫되 버리지 않는다 — 하단 버튼이 되살릴 재료다.
            $0.main.stashedHighlightDetail = $0.main.highlightDetail
            $0.main.highlightDetail = nil
        }
        await store.receive(\.main.delegate.videoRequested) {
            $0.path[id: 0] = .videoPlayer(ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                startAt: 12,
                cards: InterviewReportFixtures.ready.cards ?? [],
                script: InterviewReportFixtures.ready.script ?? [],
                entry: .highlightSheet
            ))
        }
        #expect(store.state.path[id: 0]?.videoPlayer?.isReturnToPreviousVisible == true)
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

    /// 시트 «영상 보러가기» 로 플레이어까지 들어와 있는 상태 — 접어 둔 시트가 옆에 있다.
    private func playerFromSheetState() -> ReportFeature.State {
        var state = loadedState()
        state.main.stashedHighlightDetail = Self.highlightDetail
        state.path.append(.videoPlayer(ReportVideoPlayerFeature.State(
            videoURL: URL(string: "https://example.com/interview/1.mp4")!,
            startAt: 12,
            entry: .highlightSheet
        )))
        return state
    }

    @Test("플레이어 하단 «이전 화면으로 가기» → pop 하고 왔던 상세 시트를 다시 올린다")
    func returnToPreviousReopensSheet() async {
        let store = TestStore(initialState: playerFromSheetState()) { ReportFeature() }

        await store.send(.path(.element(id: 0, action: .videoPlayer(.view(.userTappedReturnToPrevious)))))
        await store.receive(\.path[id: 0].videoPlayer.delegate.returnToHighlightSheetRequested) {
            $0.path = StackState()
            $0.main.highlightDetail = Self.highlightDetail
            $0.main.stashedHighlightDetail = nil
        }
    }

    @Test("플레이어 상단 X → 리포트 메인까지만, 접어 둔 시트는 버린다")
    func playerCloseDropsStashedSheet() async {
        let store = TestStore(initialState: playerFromSheetState()) { ReportFeature() }

        await store.send(.path(.element(id: 0, action: .videoPlayer(.view(.userTappedBack)))))
        await store.receive(\.path[id: 0].videoPlayer.delegate.backRequested) {
            $0.path = StackState()
            $0.main.stashedHighlightDetail = nil
        }
    }

    @Test("이탈(X)은 부모로 전파된다")
    func closePropagates() async {
        let store = TestStore(initialState: loadedState()) { ReportFeature() }

        await store.send(.main(.view(.userTappedClose)))
        await store.receive(\.main.delegate.closeRequested)
        await store.receive(\.delegate.closeRequested)
    }
}
