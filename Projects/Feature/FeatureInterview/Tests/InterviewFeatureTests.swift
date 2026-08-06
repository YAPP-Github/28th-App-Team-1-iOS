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
import Foundation
import Testing

@testable import FeatureInterviewImplementation

// 코디네이터 delegate 라우팅을 분기별로 고정한다 — 화면 전환·캡처 정지·상위 통보.
@MainActor
struct InterviewFeatureTests {
    @Test("세션 종료는 녹화 산출물을 리포트 대기 화면에 넘기고, 홈으로 탭이 상위에 종료를 통보한다")
    func sessionFinishRoutesThroughReportPending() async {
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        // stopPlayback 은 스텁하지 않는다 — 정상 종료가 마무리 멘트 재생을 끊으면 unimplemented 가 잡는다.
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
            $0.recordingClient.discardRecording = {}   // 홈으로 이탈이 부른다(업로드 미완 정리)
            $0.speechClient.stopCapture = {}
        }

        await store.send(.screen(.session(.delegate(.finished(.fixture, .fixture))))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State(
                recording: .fixture, wrapUp: .fixture
            ))
        }
        await store.send(.screen(.reportPending(.view(.userTappedGoHome))))
        await store.receive(\.screen.reportPending.delegate.goHomeRequested)
        await store.receive(\.delegate.finished)
        await store.finish()
    }

    @Test("리포트 대기 전환 후 도착한 두 번째 세션 종료 통보는 화면을 다시 갈아끼우지 않는다")
    func duplicateSessionFinishDoesNotResetReportPending() async {
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
            $0.speechClient.stopCapture = {}
        }
        let reportPending = InterviewFeature.Screen.State.reportPending(
            InterviewReportPendingFeature.State(recording: .fixture, wrapUp: .fixture)
        )

        await store.send(.screen(.session(.delegate(.finished(.fixture, .fixture))))) {
            $0.screen = reportPending
        }
        // 세션 effect 는 화면 교체로 취소되지 않는다(Scope-on-enum) — 뒤늦은 두 번째 통보가 도달할 수 있다.
        // 상태가 다른 case 라 ifCaseLet 이 경고를 남기는 것까지가 재현하려는 상황.
        await withKnownIssue {
            await store.send(.screen(.session(.delegate(.finished(nil, nil)))))
        } matching: {
            isStaleChildActionWarning($0)
        }
        // 블록 **밖에서** 단언한다 — 안에 두면 가드를 지운 뮤턴트의 상태 불일치까지 known 으로 흡수된다.
        // 가드가 없으면 payload 가 nil 로 씻긴 새 State 로 갈아끼워져 여기서 죽는다.
        #expect(store.state.screen == reportPending)
        await store.finish()
    }

    @Test("리포트 대기 전환 후 도착한 늦은 중단·실패 통보도 무시한다 — 업로드 중인 파일을 지우지 않는다")
    func staleSessionAbortOrFailureLeavesReportPendingIntact() async {
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        // discardRecording·stopPlayback 미스텁 — 가드가 뚫려 이탈·실패 헬퍼가 돌면 unimplemented 가 잡는다.
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
            $0.speechClient.stopCapture = {}
        }
        let reportPending = InterviewFeature.Screen.State.reportPending(
            InterviewReportPendingFeature.State(recording: .fixture, wrapUp: .fixture)
        )

        await store.send(.screen(.session(.delegate(.finished(.fixture, .fixture))))) {
            $0.screen = reportPending
        }
        await withKnownIssue {
            await store.send(.screen(.session(.delegate(.aborted))))
            await store.send(.screen(.session(.delegate(.failed(.network)))))
        } matching: {
            isStaleChildActionWarning($0)
        }
        #expect(store.state.screen == reportPending)
        await store.finish()
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
            $0.recordingClient.discardRecording = {}
            $0.speechClient.stopCapture = {}
            $0.speechClient.stopPlayback = {}
        }

        await store.send(.screen(.readiness(.delegate(.prepFailed)))) {
            $0.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        }
        await store.finish()
    }

    @Test("정상 종료 전환은 카메라·마이크만 정지한다 — 재생도 녹화 폐기도 하지 않는다")
    func leavingCaptureScreensStopsDevices() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        // stopPlayback·discardRecording 미스텁 — 정상 종료가 마무리 멘트를 끊거나 산출 파일을 지우면
        // (업로드가 그 파일을 써야 한다) unimplemented 가 잡는다.
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.session(.delegate(.finished(.fixture, .fixture))))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State(
                recording: .fixture, wrapUp: .fixture
            ))
        }
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
    }

    @Test("실패 화면 X(닫기)로 흐름을 떠날 때도 캡처 장치·재생을 정지하고 녹화를 폐기한 뒤 종료를 통보한다")
    func closingFromFailureStopsDevices() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        let recordingDiscarded = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.recordingClient.discardRecording = { recordingDiscarded.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
            $0.speechClient.stopPlayback = { playbackStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.failure(.delegate(.closeRequested))))
        await store.receive(\.delegate.closed)
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
        #expect(playbackStopped.value == 1)
        #expect(recordingDiscarded.value == 1)
    }

    @Test("준비 화면 뒤로가기는 캡처 장치를 정지한 뒤 상위에 종료를 통보한다 — 모달 없이 즉시 이탈")
    func readinessBackStopsDevicesThenNotifiesClosed() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        let recordingDiscarded = LockIsolated(0)
        let store = TestStore(initialState: InterviewFeature.State(sessionId: 1)) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.recordingClient.discardRecording = { recordingDiscarded.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
            $0.speechClient.stopPlayback = { playbackStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.readiness(.delegate(.backRequested))))
        await store.receive(\.delegate.closed)
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
        #expect(playbackStopped.value == 1)
        // 준비 화면엔 녹화가 없지만 폐기는 멱등이라 그대로 부른다(경로별 분기 없음).
        #expect(recordingDiscarded.value == 1)
    }

    @Test("세션 중도 이탈은 화면 전환 없이 캡처 장치·재생을 정지하고 녹화를 폐기한 뒤 종료를 통보한다")
    func sessionAbortStopsDevicesThenNotifiesClosed() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        let recordingDiscarded = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.recordingClient.discardRecording = { recordingDiscarded.withValue { $0 += 1 } }
            $0.speechClient.stopCapture = { captureStopped.withValue { $0 += 1 } }
            $0.speechClient.stopPlayback = { playbackStopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.session(.delegate(.aborted))))
        await store.receive(\.delegate.closed)
        await store.finish()
        #expect(previewStopped.value == 1)
        #expect(captureStopped.value == 1)
        #expect(playbackStopped.value == 1)
        #expect(recordingDiscarded.value == 1)
    }

    @Test("세션 실패 통보는 같은 kind 의 실패 화면으로 전환하고 캡처 장치·재생 정지·녹화 폐기를 한다")
    func sessionFailureRoutesToFailureScreen() async {
        let previewStopped = LockIsolated(0)
        let captureStopped = LockIsolated(0)
        let playbackStopped = LockIsolated(0)
        let recordingDiscarded = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(.fixture)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { previewStopped.withValue { $0 += 1 } }
            $0.recordingClient.discardRecording = { recordingDiscarded.withValue { $0 += 1 } }
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
        #expect(recordingDiscarded.value == 1)
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

// MARK: - 늦은 자식 delegate 재현 보조

/// ifCaseLet 이 «다른 case 의 자식 액션» 에 남기는 경고 — 늦은 delegate 재현 테스트가 의도적으로 유발한다.
/// `withKnownIssue` 를 필터 없이 쓰면 블록 안의 TestStore 단언 실패까지 known 으로 흡수돼
/// 가드를 지운 뮤턴트가 살아남는다. 이 필터가 그 흡수 범위를 프레임워크 경고 하나로 좁힌다.
private func isStaleChildActionWarning(_ issue: Issue) -> Bool {
    issue.description.contains("child action")
        || issue.comments.contains { $0.description.contains("child action") }
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

private extension RecordingRef {
    /// 세션이 넘기는 녹화 산출물 — 코디네이터는 내용을 보지 않고 그대로 전달만 한다.
    static let fixture = RecordingRef(
        sessionId: 1, fileURL: URL(fileURLWithPath: "/tmp/interview-1.mp4"), durationSeconds: 600
    )
}

private extension InterviewVideoWrapUpSpan {
    /// 마무리 멘트 구간 — 리포트 대기 화면까지 그대로 실려 간다.
    static let fixture = InterviewVideoWrapUpSpan(wrapUpStartSec: 500, wrapUpEndSec: 512)
}
