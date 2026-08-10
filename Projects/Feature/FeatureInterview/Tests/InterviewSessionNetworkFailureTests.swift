//
//  InterviewSessionNetworkFailureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/08/06.
//

import ComposableArchitecture
import DomainInterviewInterface
import Foundation
import Testing

@testable import FeatureInterviewImplementation

// 네트워크 실패 오버레이 상태기계 — 세션 유지·유효시간 정지·실패 지점 재시도·제출 없는 중단 (스펙 ③).
@MainActor
struct InterviewSessionNetworkFailureTests {
    @Test("질문 재생 재시도 소진은 delegate 대신 네트워크 오버레이를 세우고 재생 재시도를 보관한다")
    func playbackExhaustionPresentsOverlay() async {
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.hasRetriedPlayback = true   // 1회 재시도 이미 소진
        let store = TestStore(initialState: state) { InterviewSessionFeature() }

        await store.send(.inner(.questionPlaybackFailed)) {
            $0.failure = InterviewFailureFeature.State(kind: .network)
            $0.pendingRetry = .playQuestion
            $0.toast = nil
        }
        await store.finish()   // delegate(.failed) 가 나가면 여기서 잡힌다
    }

    @Test("오버레이 동안 시계 tick 은 영상 축(elapsed)만 올리고 유효시간·해금 판정은 멈춘다")
    func tickDuringOverlaySuspendsInterviewLogic() async {
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.elapsedSeconds = InterviewSessionFeature.exitUnlockSeconds - 1   // 다음 유효 tick 이 해금 경계
        state.failure = InterviewFailureFeature.State(kind: .network)
        state.pendingRetry = .playQuestion
        let store = TestStore(initialState: state) { InterviewSessionFeature() }

        await store.send(.inner(.clockTicked)) {
            $0.elapsedSeconds = InterviewSessionFeature.exitUnlockSeconds
            $0.suspendedSeconds = 1
        }
        // 유효시간 479 — 해금(480) 미도달: isExitAvailable·토스트 없음이 위 상태 단언으로 고정된다.
        #expect(store.state.effectiveElapsedSeconds == InterviewSessionFeature.exitUnlockSeconds - 1)
    }

    @Test("이어서 진행하기(재생 재시도)는 오버레이를 닫고 질문 재생을 다시 열며 시작 마킹을 영상 축으로 갱신한다")
    func resumeReplaysQuestion() async {
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.elapsedSeconds = 100
        state.suspendedSeconds = 40
        state.failure = InterviewFailureFeature.State(kind: .network)
        state.pendingRetry = .playQuestion
        let store = TestStore(initialState: state) { InterviewSessionFeature() }
        store.dependencies.interviewClient.questionAudioStream = { stubAudioStream($0, $1) }
        store.dependencies.speechClient.playStream = { _, _ in finishedPlayback() }
        store.dependencies.speechClient.setSessionAudioMuted = { _ in }
        store.dependencies.speechClient.startAnswerRecording = {}

        await store.send(.failure(.presented(.delegate(.resumeRequested)))) {
            $0.failure = nil
            $0.pendingRetry = nil
            $0.questionAudioStartedAt = 100   // 재생 재시작 시점 — 영상 타임라인 축(raw elapsed)
        }
        await store.receive(\.inner.questionPlaybackFinished) {
            $0.phase = .answering
            $0.questionAudioEndedAt = 100
            $0.answerStartedAt = 100
        }
        await store.finish()
    }

    @Test("제출 실패는 오디오 포함 submission 을 보관하고, 재개는 answerAudio 재소모 없이 같은 payload 를 재전송한다")
    func submitFailureStoresSubmissionAndResumeResubmits() async {
        var submission = AnswerSubmission(questionId: 1, isWrapUp: false)
        submission.audio = Data("answer".utf8)
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.phase = .processingAnswer
        let store = TestStore(initialState: state) { InterviewSessionFeature() }
        let stored = submission

        await store.send(.inner(.answerSubmissionFailed(.unexpected, stored))) {
            $0.failure = InterviewFailureFeature.State(kind: .network)
            $0.pendingRetry = .submit(stored)
            $0.toast = nil
        }

        // 재개 — speechClient.answerAudio 는 스텁하지 않는다: 재소모하면 unimplemented 가 잡는다(1회 소모성 계약).
        let submitted = LockIsolated<[AnswerSubmission]>([])
        store.dependencies.interviewClient.submitAnswer = { _, submission in
            submitted.withValue { $0.append(submission) }
            return .ended(.manualEnd)
        }
        store.dependencies.speechClient.play = { _ in finishedPlayback() }
        store.dependencies.speechClient.stopPlayback = {}
        await store.send(.failure(.presented(.delegate(.resumeRequested)))) {
            $0.failure = nil
            $0.pendingRetry = nil
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) {
            $0.isSubmitting = false
        }
        // 세션 종료 후속(sessionCleanup·finished(nil,nil))은 이 테스트 관심 밖 — 도착만 소화한다.
        await store.receive(\.delegate.finished)
        await store.finish()
        #expect(submitted.value == [stored])   // 같은 payload(오디오 포함) 그대로
    }

    @Test("오버레이 중단하기는 서버 제출 없이 abandon 만 보내고 aborted 를 올린다 — 이용권 미차감 문구 계약")
    func abortFromOverlayNotifiesAbortedWithoutSubmit() async {
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.failure = InterviewFailureFeature.State(kind: .network)
        state.pendingRetry = .playQuestion
        // interviewClient.submitAnswer 미스텁 — BACK_EXIT 제출이 나가면 unimplemented 가 잡는다.
        // (abandon 은 제출이 아니라 중단 API 라 이 계약을 깨지 않는다.)
        let store = TestStore(initialState: state) { InterviewSessionFeature() }
        store.dependencies.continuousClock = TestClock()   // 안 흘린다 — 즉답 abandon 이 3초 레이스를 먼저 끝낸다
        store.dependencies.interviewClient.abandonSession = { _, _ in .stub }
        store.dependencies.heldSessionStore.clear = {}

        // 오버레이는 남는다 — 이탈이 확정될 때까지가 «진행 중» 이고, 걷어 가는 건 코디네이터의 teardown 이다.
        await store.send(.failure(.presented(.delegate(.closeRequested)))) {
            $0.pendingRetry = nil
            $0.isAbandoning = true
        }
        await store.receive(\.delegate.aborted)
        await store.finish()
    }

    @Test("오버레이 중단하기는 abandon(NETWORK_DISCONNECT) 를 3초 레이스로 시도하고 결과와 무관하게 이탈한다")
    func overlayCloseAbandonsWithNetworkDisconnect() async {
        let clock = TestClock()
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.failure = InterviewFailureFeature.State(kind: .network)
        state.pendingRetry = .playQuestion
        let abandoned = LockIsolated<AbandonCause?>(nil)
        let cleared = LockIsolated(false)
        let store = TestStore(initialState: state) { InterviewSessionFeature() }
        store.dependencies.continuousClock = clock
        store.dependencies.interviewClient.abandonSession = { _, cause in
            abandoned.setValue(cause)
            // 오프라인 시늉 — 영영 안 끝나는 요청. 3초 레이스가 이탈을 지켜야 한다.
            try await Task.never()
            return .stub   // 도달 불가 — Task.never() 는 취소로만 끝난다(컴파일러가 반환문을 요구할 뿐)
        }
        store.dependencies.heldSessionStore.clear = { cleared.setValue(true) }

        await store.send(.failure(.presented(.delegate(.closeRequested)))) {
            $0.pendingRetry = nil
            $0.isAbandoning = true
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.delegate.aborted)
        #expect(abandoned.value == .networkDisconnect)
        #expect(cleared.value)
    }

    // 오버레이는 즉시 닫히는데 이탈은 최대 3초 뒤다 — 그 창의 세션 화면은 «살아 있는 것처럼» 보인다.
    // 잠금이 없으면 X→[이탈하기]가 BACK_EXIT 를 제출해 «제출 없이 중단» 계약이 깨지고, 8분 후엔
    // X→[마치기]가 MANUAL_END 로 버린 세션의 영상을 업로드 큐에 넣는다. 백그라운드는 held 를 되살린다.
    @Test("중단 레이스 창(최대 3초) 동안 입력은 전면 잠긴다 — 제출·동결 재발사 없이 이탈만 남는다")
    func inputsAreLockedDuringAbandonRace() async {
        let clock = TestClock()
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.isExitAvailable = true   // 8분 경과 — X 가 종료 확인 모달을 열 수 있는 조건까지 열어 둔다
        state.failure = InterviewFailureFeature.State(kind: .network)
        state.pendingRetry = .playQuestion
        let store = TestStore(initialState: state) { InterviewSessionFeature() }
        store.dependencies.continuousClock = clock
        // submitAnswer·finishSessionAudioRecording·heldSessionStore.save 미스텁 —
        // 잠금이 뚫려 제출이나 동결이 발사되면 unimplemented 가 잡는다.
        store.dependencies.interviewClient.abandonSession = { _, _ in
            try await Task.never()
            return .stub
        }
        store.dependencies.heldSessionStore.clear = {}

        await store.send(.failure(.presented(.delegate(.closeRequested)))) {
            $0.pendingRetry = nil
            $0.isAbandoning = true
        }
        // 레이스가 도는 동안의 입력·잔광은 전부 죽는다 — 상태 무변화(클로저 없음) + effect 없음.
        await store.send(.view(.userTappedClose))
        await store.send(.view(.userTappedLeaveInterview))
        await store.send(.view(.userTappedFinishInterview))
        await store.send(.view(.sceneBackgrounded))
        await store.send(.inner(.clockTicked))
        // 오버레이가 그대로 떠 있어 [중단하기]도 계속 눌린다 — 재탭은 abandon 재발사 없이 no-op 이다
        // (뚫리면 두 번째 레이스가 뒤늦은 aborted 를 하나 더 올려 아래 receive 가 못 받고 남는다).
        await store.send(.failure(.presented(.delegate(.closeRequested))))

        // 그래도 이탈은 제 시각에 온다 — 잠금이 레이스 effect 자신을 막지 않는다(delegate 는 잠금 밖).
        await clock.advance(by: .seconds(3))
        await store.receive(\.delegate.aborted)
    }

    @Test("유효시간이 랩업 임계를 넘어야 isWrapUp 제출이 된다 — 정지 구간은 임계 계산에서 빠진다")
    func wrapUpThresholdUsesEffectiveSeconds() async {
        var state = InterviewSessionFeature.State.fixture(hasStarted: true)
        state.phase = .answering
        state.elapsedSeconds = InterviewSessionFeature.wrapUpThresholdSeconds + 30   // 영상 축은 임계 초과
        state.suspendedSeconds = 60                                                  // 유효시간은 임계 미달
        let store = TestStore(initialState: state) { InterviewSessionFeature() }
        let submitted = LockIsolated<[AnswerSubmission]>([])
        store.dependencies.interviewClient.submitAnswer = { _, submission in
            submitted.withValue { $0.append(submission) }
            return .ended(.manualEnd)
        }
        store.dependencies.speechClient.answerAudio = { nil }
        store.dependencies.speechClient.play = { _ in finishedPlayback() }
        store.dependencies.speechClient.stopPlayback = {}

        await store.send(.view(.userTappedAnswerComplete)) {
            $0.phase = .processingAnswer
            $0.isSubmitting = true
        }
        await store.receive(\.inner.answerSubmitted) { $0.isSubmitting = false }
        await store.receive(\.delegate.finished)
        await store.finish()
        #expect(submitted.value.first?.isWrapUp == false)
    }
}
