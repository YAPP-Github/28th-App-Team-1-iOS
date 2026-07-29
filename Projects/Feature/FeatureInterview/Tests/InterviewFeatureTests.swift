//
//  InterviewFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/27.
//

import AVFoundation
import ComposableArchitecture
import DomainRecordingInterface
import Testing

@testable import FeatureInterviewImplementation

// 코디네이터 화면 전환 중 «세션 종료 → 리포트 대기 경유 → 상위 통보» 만 고정한다.
@MainActor
struct InterviewFeatureTests {
    @Test("세션 종료는 리포트 대기 화면을 경유하고, 홈으로 탭이 상위에 종료를 통보한다")
    func sessionFinishRoutesThroughReportPending() async {
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(InterviewSessionFeature.State())
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
        }

        await store.send(.screen(.session(.delegate(.finished)))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State())
        }
        await store.send(.screen(.reportPending(.view(.userTappedGoHome))))
        await store.receive(\.screen.reportPending.delegate.goHomeRequested)
        await store.receive(\.delegate.finished)
    }

    @Test("면접 시작 전환은 준비 화면의 프리뷰 핸들을 세션 상태로 승계한다 — 전환 중 placeholder 깜빡임 방지")
    func startRequestedSeedsPreviewHandle() async {
        let handle = CameraPreviewHandle(session: AVCaptureSession())
        var readiness = InterviewReadinessFeature.State(sessionId: 1)
        readiness.previewHandle = handle
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .readiness(readiness)
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        }

        await store.send(.screen(.readiness(.delegate(.startRequested)))) {
            $0.screen = .session(InterviewSessionFeature.State(previewHandle: handle))
        }
    }

    @Test("질문 준비 실패는 questionPrep 실패 화면으로 전환한다")
    func prepFailedRoutesToFailure() async {
        let store = TestStore(initialState: InterviewFeature.State(sessionId: 1)) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = {}
        }

        await store.send(.screen(.readiness(.delegate(.prepFailed)))) {
            $0.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        }
    }

    @Test("카메라 화면을 떠나는 전환은 프리뷰를 정지한다")
    func leavingCameraScreensStopsPreview() async {
        let stopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .session(InterviewSessionFeature.State())
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { stopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.session(.delegate(.finished)))) {
            $0.screen = .reportPending(InterviewReportPendingFeature.State())
        }
        await store.finish()
        #expect(stopped.value == 1)
    }

    @Test("실패 화면 X(닫기)로 흐름을 떠날 때도 프리뷰를 정지하고 종료를 통보한다")
    func closingFromFailureStopsPreview() async {
        let stopped = LockIsolated(0)
        var initialState = InterviewFeature.State(sessionId: 1)
        initialState.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
        let store = TestStore(initialState: initialState) {
            InterviewFeature()
        } withDependencies: {
            $0.recordingClient.stopPreview = { stopped.withValue { $0 += 1 } }
        }

        await store.send(.screen(.failure(.delegate(.closeRequested))))
        await store.receive(\.delegate.closed)
        await store.finish()
        #expect(stopped.value == 1)
    }
}
