//
//  InterviewSessionFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/25.
//

import AVFoundation
import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import DomainSpeechInterface
import Foundation
import Testing

@testable import FeatureInterviewImplementation

// 세션 시계 상태머신(8:00 해금 → 11:50 카운트다운 → 12:00 HARD_CAP 제출)·턴 루프(제출 응답 분기)·
// 종료 경로(제출 경유)·503 백오프를 고정한다 — 화면 렌더링은 순수 UI 라 프리뷰 육안 검증.
@MainActor
struct InterviewSessionFeatureTests {
    @Test("진입 시 프리뷰 핸들을 확보한다 — 준비 화면이 켜 둔 세션의 멱등 승계")
    func onAppearAcquiresPreviewHandle() async {
        let clock = TestClock()
        let handle = CameraPreviewHandle(session: AVCaptureSession())
        let store = TestStore(initialState: .fixture()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { handle }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
            $0.speechClient.playStream = { _, _ in finishedPlayback() }
            $0.interviewClient.questionAudioStream = stubAudioStream
        }
        store.exhaustivity = .off   // 세션 시계·재생 전이는 다른 테스트가 고정 — 여기선 핸들 확보만 본다.

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(store.state.previewHandle == handle)
    }

    @Test("진입 시 마이크 캡처 스트림을 구독하고 요약 질문 재생을 시작한다")
    func onAppearStartsMicCaptureAndSummaryPlayback() async {
        let clock = TestClock()
        let captureStarted = LockIsolated(false)
        let played = LockIsolated<Data?>(nil)
        // 요약 질문에 mp3 동봉("bXAz" = "mp3") — 스트림이 아니라 play 로 재생돼야 한다.
        let store = TestStore(initialState: .fixture(summaryAudio: "bXAz")) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = {
                captureStarted.setValue(true)
                return AsyncStream { $0.finish() }
            }
            $0.speechClient.play = { data in
                played.setValue(data)
                return finishedPlayback()
            }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(captureStarted.value)
        #expect(played.value == Data("mp3".utf8))
        #expect(store.state.phase == .answering)   // 재생 완료 → 답변 녹음으로
    }

    @Test("8분 경과 시 종료가 해금되고 안내 토스트가 떴다가 사라진다")
    func exitUnlocksAtEightMinutes() async {
        let clock = TestClock()
        let store = TestStore(initialState: .fixture()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
            $0.speechClient.playStream = { _, _ in finishedPlayback() }
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.questionAudioStream = stubAudioStream
            $0.interviewClient.submitAnswer = { _, _ in .ended(.manualEnd) }
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

        await store.send(.view(.userTappedFinishInterview))   // MANUAL_END 제출 → 세션 정리
        await store.finish()
    }

    @Test("상한 10초 전(11:50) 최종 카운트다운으로 전환되고 12:00 도달 시 HARD_CAP 을 제출해 종료한다")
    func finalCountdownThenHardCapSubmission() async {
        let clock = TestClock()
        let captured = LockIsolated<AnswerSubmission?>(nil)
        let store = TestStore(initialState: .fixture()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
            $0.speechClient.playStream = { _, _ in finishedPlayback() }
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.questionAudioStream = stubAudioStream
            $0.interviewClient.submitAnswer = { _, submission in
                captured.setValue(submission)
                return .ended(.hardCap)
            }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(710))   // 11:50
        await store.skipReceivedActions()
        #expect(store.state.phase == .finalCountdown)
        #expect(store.state.toast == .timeExpired)
        #expect(store.state.countdownRemaining == 10)

        await clock.advance(by: .seconds(10))    // 12:00 hard cap — 제출 경유 종료
        await store.receive(\.delegate.finished)
        #expect(captured.value?.endType == .hardCap)
        #expect(captured.value?.isWrapUp == true)
        await store.finish()
    }

    @Test("8분 후 X 는 중도 이탈 경고가 아니라 종료 확인 모달로 간다")
    func lateCloseRoutesToExitConfirm() async {
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.isExitAvailable = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        }

        await store.send(.view(.userTappedClose)) {
            $0.isExitConfirmPresented = true
        }
    }

    @Test("실패 감지는 열린 모달과 진행 중인 세션 effect(재생 포함)를 정리하고 실패를 통보한다")
    func failureDetectedCleansUpAndNotifiesFailure() async {
        let clock = TestClock()
        var initialState = InterviewSessionFeature.State.fixture()
        initialState.isExitConfirmPresented = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
            // 끝나지 않는 재생 스트림 — 정리(cancel)가 안 되면 finish 에서 잡힌다.
            $0.speechClient.playStream = { _, _ in AsyncStream { _ in } }
            $0.interviewClient.questionAudioStream = stubAudioStream
        }
        store.exhaustivity = .off   // 시계 틱은 기존 테스트가 고정 — 여기선 정리·통보만 본다.

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(1))   // 세션 시계·재생 effect 가 실제로 돌고 있는 상태를 만든다.
        await store.skipReceivedActions()

        await store.send(.inner(.failureDetected(.network)))
        await store.receive(\.delegate.failed, .network)
        #expect(store.state.isExitConfirmPresented == false)
        await store.finish()   // 시계·마이크·재생 effect 가 취소되지 않았으면 여기서 실패한다.
    }
}

// 답변 제출·턴 루프(응답 분기·503 백오프·종료 제출 경유)를 고정한다 — 세션 시계·진입·정리는 위 스위트.
@MainActor
struct InterviewSessionSubmissionTests {
    @Test("답변 완료는 제출을 거쳐 다음 질문 asking 으로 복귀하고 시간 마킹을 싣는다")
    func answerCompleteSubmitsThenAsksNextQuestion() async {
        let captured = LockIsolated<AnswerSubmission?>(nil)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        initialState.elapsedSeconds = 45
        initialState.questionAudioStartedAt = 20
        initialState.questionAudioEndedAt = 30
        initialState.answerStartedAt = 30
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { Data("answer".utf8) }
            $0.speechClient.playStream = { _, _ in finishedPlayback() }
            $0.interviewClient.questionAudioStream = stubAudioStream
            $0.interviewClient.submitAnswer = { _, submission in
                captured.setValue(submission)
                return .next(13)
            }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
            $0.phase = .asking
            $0.currentQuestion = InterviewSessionFeature.ActiveQuestion(questionId: 13, turnLevel: 1, isLast: false)
            $0.questionAudioStartedAt = 45
            $0.questionAudioEndedAt = nil
            $0.answerStartedAt = nil
        }
        await store.receive(\.inner.questionPlaybackFinished) {
            $0.phase = .answering
            $0.questionAudioEndedAt = 45
            $0.answerStartedAt = 45
        }

        let submission = captured.value
        #expect(submission?.questionId == 1)
        #expect(submission?.audio == Data("answer".utf8))
        #expect(submission?.questionAudioStartAt == 20)
        #expect(submission?.questionAudioEndAt == 30)
        #expect(submission?.answerStartAt == 30)
        #expect(submission?.answerEndAt == 45)
        #expect(submission?.answerDuration == 15)
        #expect(submission?.isWrapUp == false)
        #expect(submission?.endType == nil)
    }

    @Test("NORMAL_END 응답은 마무리 멘트 재생을 걸어두기만 하고 즉시 종료를 통보한다")
    func normalEndPlaysWrapUpFireAndForget() async {
        let played = LockIsolated<Data?>(nil)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { nil }
            $0.speechClient.play = { data in
                played.setValue(data)
                return AsyncStream { _ in }   // 끝나지 않는 재생 — 종료 통보가 완료를 기다리면 테스트가 멈춘다
            }
            $0.interviewClient.submitAnswer = { _, _ in .ended(.normalEnd, wrapUp: "bXAz") }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.finished)
        await store.finish()   // fire-and-forget 이라 재생 완료 없이도 effect 가 남지 않는다
        #expect(played.value == Data("mp3".utf8))
    }

    @Test("STT_RESET 응답은 음성 인식 실패를 통보한다 — 서버 판정(이용권 환불·리포트 없음)")
    func sttResetNotifiesSpeechRecognitionFailure() async {
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, _ in .ended(.sttReset) }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.failed, .speechRecognition)
    }

    @Test("503 은 1초·3초 백오프로 같은 제출을 재시도하고 성공하면 이어간다")
    func serverBusyRetriesWithBackoff() async {
        let clock = TestClock()
        let attempts = LockIsolated(0)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, _ in
                let attempt = attempts.withValue { $0 += 1; return $0 }
                guard attempt >= 3 else { throw InterviewError.aiTemporarilyUnavailable }
                return .ended(.normalEnd)
            }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await clock.advance(by: .seconds(1))   // 1차 백오프
        await clock.advance(by: .seconds(3))   // 2차 백오프
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.finished)
        #expect(attempts.value == 3)
    }

    @Test("503 재시도가 소진되면 네트워크 실패로 넘어간다")
    func serverBusyRetryExhaustionFails() async {
        let clock = TestClock()
        let attempts = LockIsolated(0)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, _ in
                attempts.withValue { $0 += 1 }
                throw InterviewError.aiTemporarilyUnavailable
            }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await clock.advance(by: .seconds(1))
        await clock.advance(by: .seconds(3))
        await store.receive(\.inner.answerSubmissionFailed) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.failed, .network)
        #expect(attempts.value == 3)
    }

    @Test("이미 종료된 세션(409) 제출은 실패가 아니라 리포트 대기로 넘어간다")
    func sessionAlreadyEndedRoutesToFinished() async {
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, _ in throw InterviewError.sessionAlreadyEnded }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmissionFailed) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.finished)
    }

    @Test("8:45 경과 후 제출은 isWrapUp=true 를 싣는다")
    func wrapUpFlagAfterThreshold() async {
        let captured = LockIsolated<AnswerSubmission?>(nil)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        initialState.elapsedSeconds = InterviewSessionFeature.wrapUpThresholdSeconds + 1
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, submission in
                captured.setValue(submission)
                return .ended(.normalEnd)
            }
        }

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.finished)
        #expect(captured.value?.isWrapUp == true)
    }

    @Test("제출 중 답변 완료 재탭은 무시된다 — 중복 제출 가드")
    func duplicateAnswerCompleteIgnoredWhileSubmitting() async {
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        initialState.isSubmitting = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        }

        await store.send(.view(.userTappedAnswerComplete))   // 상태 무변화·effect 없음
    }

    @Test("마치기는 확인 모달을 닫고 MANUAL_END 를 제출해 응답으로 종료한다")
    func finishConfirmationSubmitsManualEnd() async {
        let captured = LockIsolated<AnswerSubmission?>(nil)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .answering
        initialState.isExitAvailable = true
        initialState.isExitConfirmPresented = true
        initialState.elapsedSeconds = 500
        initialState.answerStartedAt = 490
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, submission in
                captured.setValue(submission)
                return .ended(.manualEnd)
            }
        }

        await store.send(.view(.userTappedFinishInterview)) {
            $0.isExitConfirmPresented = false
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.finished)
        #expect(captured.value?.endType == .manualEnd)
    }

    @Test("8분 전 나가기는 BACK_EXIT 를 최선 노력 제출한 뒤 중단을 통보한다")
    func earlyExitSubmitsBestEffortThenAborts() async {
        let captured = LockIsolated<AnswerSubmission?>(nil)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.elapsedSeconds = 100
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.interviewClient.submitAnswer = { _, submission in
                captured.setValue(submission)
                return .ended(.backExit)
            }
        }

        await store.send(.view(.userTappedClose)) {
            $0.isEarlyExitWarningPresented = true
        }
        await store.send(.view(.userTappedLeaveInterview)) {
            $0.isEarlyExitWarningPresented = false
        }
        await store.receive(\.inner.earlyExitSubmissionFinished)
        await store.receive(\.delegate.aborted)
        #expect(captured.value?.endType == .backExit)
        #expect(captured.value?.audio == nil)   // 최선 노력 — 오디오·백오프 재시도 없음
    }

    @Test("BACK_EXIT 제출이 실패해도 이탈은 진행된다")
    func earlyExitProceedsDespiteSubmissionFailure() async {
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.isEarlyExitWarningPresented = true
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.interviewClient.submitAnswer = { _, _ in throw InterviewError.networkFailure }
        }

        await store.send(.view(.userTappedLeaveInterview)) {
            $0.isEarlyExitWarningPresented = false
        }
        await store.receive(\.inner.earlyExitSubmissionFinished)
        await store.receive(\.delegate.aborted)
    }

    @Test("제출 비행 중 12:00 도달은 응답의 새 질문을 열지 않고 HARD_CAP 으로 마감한다")
    func hardCapDuringInFlightSubmissionFinalizes() async {
        let captured = LockIsolated<AnswerSubmission?>(nil)
        var initialState = InterviewSessionFeature.State.fixture(hasStarted: true)
        initialState.phase = .processingAnswer
        initialState.isSubmitting = true
        initialState.elapsedSeconds = InterviewSessionFeature.hardCapSeconds - 1
        let store = TestStore(initialState: initialState) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.submitAnswer = { _, submission in
                captured.setValue(submission)
                return .ended(.hardCap)
            }
        }

        await store.send(.inner(.clockTicked)) {
            $0.elapsedSeconds = InterviewSessionFeature.hardCapSeconds
            $0.hardCapReachedWhileSubmitting = true
        }
        // 비행 중이던 제출이 다음 질문으로 풀렸다 — 초읽기 상황이라 재생 대신 즉시 마감한다.
        await store.send(.inner(.answerSubmitted(.next(13)))) {
            $0.currentQuestion = InterviewSessionFeature.ActiveQuestion(questionId: 13, turnLevel: 1, isLast: false)
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate.finished)
        #expect(captured.value?.endType == .hardCap)
        #expect(captured.value?.questionId == 13)
    }

    @Test("중도 이탈 경고를 띄운 채 8분을 넘기면 경고가 닫히고 해금 안내로 대체된다")
    func earlyExitWarningClosesAtExitUnlock() async {
        let clock = TestClock()
        let store = TestStore(initialState: .fixture()) {
            InterviewSessionFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.recordingClient.startPreview = { nil }
            $0.speechClient.startCapture = { AsyncStream { $0.finish() } }
            $0.speechClient.playStream = { _, _ in finishedPlayback() }
            $0.speechClient.answerAudio = { nil }
            $0.interviewClient.questionAudioStream = stubAudioStream
            $0.interviewClient.submitAnswer = { _, _ in .ended(.manualEnd) }
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

        await store.send(.view(.userTappedFinishInterview))   // MANUAL_END 제출 → 세션 정리
        await store.finish()
    }
}

// MARK: - 픽스처

private extension InterviewSessionFeature.State {
    /// 표준 시작 상태 — sessionId 7, 요약 질문(questionId 1). summaryAudio 는 base64 mp3(없으면 스트림 폴백).
    static func fixture(hasStarted: Bool = false, summaryAudio: String? = nil) -> Self {
        var state = InterviewSessionFeature.State(
            sessionId: 7,
            summaryQuestion: SummaryQuestion(
                questionId: 1,
                ttsAudio: summaryAudio,
                turn: TurnInfo(turnLevel: 0, depthLevel: 0)
            )
        )
        state.hasStarted = hasStarted
        return state
    }
}

private extension AnswerResult {
    /// 다음 질문 응답 — 세션 계속.
    static func next(_ questionId: Int) -> Self {
        AnswerResult(
            answerId: 1,
            nextQuestion: NextQuestion(questionId: questionId, isLast: false, turn: TurnInfo(turnLevel: 1, depthLevel: 1)),
            sessionEnded: false,
            wrapUpMessage: nil,
            endType: nil
        )
    }

    /// 세션 종료 응답 — endType 별 분기 검증용.
    static func ended(_ type: SessionEndType, wrapUp: String? = nil) -> Self {
        AnswerResult(
            answerId: nil,
            nextQuestion: nil,
            sessionEnded: true,
            wrapUpMessage: wrapUp.map(WrapUpMessage.init(ttsAudio:)),
            endType: type
        )
    }
}

/// 즉시 완료되는 재생 스트림 — 재생 자체는 다른 계층(AudioPlaybackManager) 몫이라 이벤트만 흘린다.
private func finishedPlayback() -> AsyncStream<PlaybackEvent> {
    AsyncStream {
        $0.yield(.finished)
        $0.finish()
    }
}

/// questionAudioStream 스텁 — 경로 조립만 흉내 낸다. (전역 함수는 캡처가 없어 @Sendable 로 승격된다)
private func stubAudioStream(_ sessionId: Int, _ questionId: Int) -> InterviewAudioStream {
    InterviewAudioStream(url: URL(string: "stub://\(sessionId)/\(questionId)")!, headers: [:])
}
