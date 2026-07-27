//
//  InterviewSessionFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import Testing

@testable import FeatureInterviewImplementation

// 세션 시계 상태머신(8:00 해금 → 9:50 카운트다운 → 10:00 종료)만 고정한다 —
// 나머지 화면 상태는 순수 UI 라 프리뷰 육안 검증.
@MainActor
struct InterviewSessionFeatureTests {
    @Test("8분 경과 시 종료가 해금되고 안내 토스트가 떴다가 사라진다")
    func exitUnlocksAtEightMinutes() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        store.exhaustivity = .off   // 1초 틱 480회를 개별 검증하지 않는다.

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(480))
        await store.skipReceivedActions()
        #expect(store.state.isExitAvailable)
        #expect(store.state.toast == .exitUnlocked)

        await clock.advance(by: InterviewSessionFeature.exitNoticeHold)
        await store.skipReceivedActions()
        #expect(store.state.toast == nil)

        await store.send(.view(.userTappedFinishInterview))   // 세션 시계 정리
        await store.finish()
    }

    @Test("상한 10초 전 최종 카운트다운으로 전환되고 상한 도달 시 종료를 통보한다")
    func finalCountdownThenFinishAtCap() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(590))
        await store.skipReceivedActions()
        #expect(store.state.phase == .finalCountdown)
        #expect(store.state.toast == .timeExpired)
        #expect(store.state.countdownRemaining == 10)

        await clock.advance(by: .seconds(10))
        await store.receive(\.delegate.finished)
        await store.finish()
    }

    @Test("답변 완료 탭은 기록 토스트를 띄우고 질문 듣기로 돌아간다")
    func answerCompleteShowsToastAndReturnsToAsking() async {
        let clock = TestClock()
        var initialState = InterviewSessionFeature.State()
        initialState.hasStarted = true   // 세션 시계 없이 턴 전환만 본다.
        initialState.phase = .answering
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .asking
            $0.toast = .answerRecorded
        }
        await clock.advance(by: InterviewSessionFeature.answerRecordedHold)
        await store.receive(\.inner.answerRecordedNoticeExpired) {
            $0.toast = nil
        }
    }

    @Test("마치기는 확인 모달을 닫고 종료를 통보한다")
    func finishConfirmationEndsSession() async {
        var initialState = InterviewSessionFeature.State()
        initialState.hasStarted = true
        initialState.isExitAvailable = true
        initialState.isExitConfirmPresented = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        }

        await store.send(.view(.userTappedFinishInterview)) {
            $0.isExitConfirmPresented = false
        }
        await store.receive(\.delegate.finished)
    }
}
