//
//  InterviewFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/27.
//

import AVFoundation
import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import DomainSpeechInterface
import Testing

@testable import FeatureInterviewImplementation

// 코디네이터 delegate 라우팅을 분기별로 고정한다 — 화면 전환·캡처 정지·상위 통보.
@MainActor
struct InterviewFeatureTests {
    @Test("세션 종료는 리포트 대기 화면을 경유하고, 홈으로 탭이 상위에 종료를 통보한다")
    func sessionFinishRoutesThroughReportPending() async {
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        // stopPlayback 은 스텁하지 않는다 — 정상 종료가 마무리 멘트 재생을 끊으면 unimplemented 가 잡는다.
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
            $0.speechClient.stopCapture = {}
        }

        await store.send(.screen(.session(.delegate(.finished)))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State())
        }
        await store.send(.screen(.reportPending(.view(.userTappedGoHome))))
        await store.receive(\.screen.reportPending.delegate.goHomeRequested)
        await store.receive(\.delegate.finished)
    }

    @Test("면접 시작 전환은 준비 화면의 요약 질문(READY 페이로드)과 프리뷰 핸들을 세션 상태로 시드한다")
    func startRequestedSeedsSummaryQuestionAndPreviewHandle() async {
        let handle = CameraPreviewHandle(session: AVCaptureSession())
        var readiness = InterviewReadinessFeature.State(sessionId: 1)
        readiness.previewHandle = handle
        readiness.questionPrep = .ready(.fixture)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .readiness(readiness)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        }

        await store.send(.screen(.readiness(.delegate(.startRequested)))) {
            $0.screen = .session(InterviewSessionFeature.State(
                sessionId: 1,
                summaryQuestion: .fixture,
                previewHandle: handle
            ))
        }
    }

    @Test("질문 준비 실패는 questionPrep 실패 화면으로 전환한다")
    func prepFailedRoutesToFailure() async {
        let store = TestStore(initialState: InterviewFeature.State(sessionId: 1)) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
            $0.speechClient.stopCapture = {}
            $0.speechClient.stopPlayback = {}
        }

        await store.send(.screen(.readiness(.delegate(.prepFailed)))) {
            $0.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        }
    }

    @Test("캡처 화면을 떠나는 전환은 카메라 프리뷰와 마이크 캡처를 정지한다 — 재생은 정지하지 않는다")
    func leavingCaptureScreensStopsDevices() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        // stopPlayback 미스텁 — 정상 종료 전환이 마무리 멘트를 끊으면 unimplemented 가 잡는다.
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.session(.delegate(.finished)))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State())
        }
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
    }

    @Test("실패 화면 X(닫기)로 흐름을 떠날 때도 캡처 장치·재생을 정지하고 종료를 통보한다")
    func closingFromFailureStopsDevices() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
            $0.speechClient.stopPlayback = { playbackStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.failure(.delegate(.closeRequested))))
        await store.receive(\.delegate.closed)
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
        #expect(playbackStopped.value == 1)
    }

    @Test("세션 중도 이탈은 화면 전환 없이 캡처 장치·재생을 정지한 뒤 상위에 종료를 통보한다")
    func sessionAbortStopsDevicesThenNotifiesClosed() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
            $0.speechClient.stopPlayback = { playbackStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.session(.delegate(.aborted))))
        await store.receive(\.delegate.closed)
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
        #expect(playbackStopped.value == 1)
    }

    @Test("세션 실패 통보는 같은 kind 의 실패 화면으로 전환하고 캡처 장치·재생을 정지한다")
    func sessionFailureRoutesToFailureScreen() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
            $0.speechClient.stopPlayback = { playbackStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.session(.delegate(.failed(.network))))) {
            $0.screen = .failure(InterviewFailureFeature.State(kind: .network))
        }
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
        #expect(playbackStopped.value == 1)
    }

    @Test("실패 화면 다시 시작하기는 같은 세션 id 로 준비 화면에 재진입한다")
    func restartReentersReadinessWithSameSession() async {
        var initialState = InterviewFeature.State(sessionId: 7)
        initialState.screen = .failure(InterviewFailureFeature.State(kind: .speechRecognition))
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        }

        await store.send(.screen(.failure(.delegate(.restartRequested)))) {
            $0.screen = .readiness(InterviewReadinessFeature.State(sessionId: 7))
        }
    }
}

// MARK: - 픽스처

private extension SummaryQuestion {
    /// READY 폴링 페이로드 — 준비 → 세션 시드 검증용 최소 형태(turnLevel=0).
    static let fixture = SummaryQuestion(
        questionId: 1, ttsAudio: nil, turn: TurnInfo(turnLevel: 0, depthLevel: 0)
    )
}

private extension InterviewSessionFeature.State {
    /// 코디네이터 라우팅 검증용 세션 화면 상태 — 내용은 라우팅에 영향 없다.
    static let fixture = InterviewSessionFeature.State(sessionId: 1, summaryQuestion: .fixture)
}
