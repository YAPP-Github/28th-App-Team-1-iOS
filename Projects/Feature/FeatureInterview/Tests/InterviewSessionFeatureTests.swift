//
//  InterviewSessionFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/25.
//

import AVFoundation
import ComposableArchitecture
import DomainRecordingInterface
import DomainSpeechInterface
import Testing

@testable import FeatureInterviewImplementation

// 세션 시계 상태머신(8:00 해금 → 11:50 카운트다운 → 12:00 종료)만 고정한다 —
// 나머지 화면 상태는 순수 UI 라 프리뷰 육안 검증.
@MainActor
struct InterviewSessionFeatureTests {
    @Test("진입 시 프리뷰 핸들을 확보한다 — 준비 화면이 켜 둔 세션의 멱등 승계")
    func onAppearAcquiresPreviewHandle() async {
        let clock = TestClock()
        let handle = CameraPreviewHandle(session: AVCaptureSession())
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { handle }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off   // 세션 시계는 기존 테스트가 고정 — 여기선 핸들 확보만 본다.

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(store.state.previewHandle == handle)
    }

    @Test("진입 시 마이크 캡처 스트림을 구독한다 — 레벨·발화 로그 검증 배선")
    func onAppearStartsMicCapture() async {
        let clock = TestClock()
        let captureStarted = LockIsolated(false)
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = {
                captureStarted.setValue(true)
                return AsyncStream { $0.finish() }
            }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(captureStarted.value)
    }

    @Test("8분 경과 시 종료가 해금되고 안내 토스트가 떴다가 사라진다")
    func exitUnlocksAtEightMinutes() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
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

    @Test("상한 10초 전(11:50) 최종 카운트다운으로 전환되고 12:00 도달 시 종료를 통보한다")
    func finalCountdownThenFinishAtCap() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(710))   // 11:50
        await store.skipReceivedActions()
        #expect(store.state.phase == .finalCountdown)
        #expect(store.state.toast == .timeExpired)
        #expect(store.state.countdownRemaining == 10)

        await clock.advance(by: .seconds(10))    // 12:00 hard cap
        await store.receive(\.delegate.finished)
        await store.finish()
    }

    @Test("답변 완료 탭은 «답변 정리 중»으로 즉시 확정하고, 정리 후 질문 듣기로 돌아간다")
    func answerCompleteProcessesThenReturnsToAsking() async {
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
            $0.phase = .processingAnswer
        }
        await clock.advance(by: InterviewSessionFeature.processingAnswerHold)
        await store.receive(\.inner.processingAnswerFinished) {
            $0.phase = .asking
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

    @Test("8분 전 X 는 이용권 차감 경고를 띄우고, 나가기는 중단(aborted)을 통보한다")
    func earlyExitWarnsThenAborts() async {
        var initialState = InterviewSessionFeature.State()
        initialState.hasStarted = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        }

        await store.send(.view(.userTappedClose)) {
            $0.isEarlyExitWarningPresented = true
        }
        await store.send(.view(.userTappedLeaveInterview)) {
            $0.isEarlyExitWarningPresented = false
        }
        await store.receive(\.delegate.aborted)
    }

    @Test("8분 후 X 는 중도 이탈 경고가 아니라 종료 확인 모달로 간다")
    func lateCloseRoutesToExitConfirm() async {
        var initialState = InterviewSessionFeature.State()
        initialState.hasStarted = true
        initialState.isExitAvailable = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        }

        await store.send(.view(.userTappedClose)) {
            $0.isExitConfirmPresented = true
        }
    }

    @Test("중도 이탈 경고를 띄운 채 8분을 넘기면 경고가 닫히고 해금 안내로 대체된다")
    func earlyExitWarningClosesAtExitUnlock() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewSessionFeature.State()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(479))   // 7:59
        await store.skipReceivedActions()

        await store.send(.view(.userTappedClose))
        #expect(store.state.isEarlyExitWarningPresented)

        await clock.advance(by: .seconds(1))     // 8:00 해금
        await store.skipReceivedActions()
        #expect(store.state.isExitAvailable)
        #expect(!store.state.isEarlyExitWarningPresented)   // 차감 경고 문구가 거짓이 되는 시점
        #expect(store.state.toast == .exitUnlocked)

        await store.send(.view(.userTappedFinishInterview))   // 세션 시계 정리
        await store.finish()
    }
}
