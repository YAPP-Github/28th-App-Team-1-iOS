//
//  InterviewReportPendingFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/08/05.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import Foundation
import Testing

@testable import FeatureInterviewImplementation

// 리포트 대기 화면의 «조용한 업로드» 정책(스펙 §④·⑤)을 고정한다 —
// 1차 실패 즉시 1회 재시도 → 2차 실패는 조용한 포기, 종착은 언제나 파일 삭제.
// 사용자에게 보이는 변화가 없는 정책이라 리듀서 테스트가 유일한 안전망이다.
@MainActor
struct InterviewReportPendingFeatureTests {
    @Test("업로드가 한 번에 성공하면 재시도 없이 파일을 지우고 끝난다")
    func uploadSucceedsOnFirstAttempt() async {
        let attempts = LockIsolated(0)
        let discarded = LockIsolated(0)
        let store = TestStore(initialState: InterviewReportPendingFeature.State(
            recording: .fixture,
            wrapUp: .fixture
        )) {
            InterviewReportPendingFeature()
        } withDependencies: {
            $0.interviewClient.uploadInterviewVideo = { sessionId, fileURL, wrapUp in
                #expect(sessionId == RecordingRef.fixture.sessionId)
                #expect(fileURL == RecordingRef.fixture.fileURL)
                #expect(wrapUp == .fixture)
                attempts.withValue { $0 += 1 }
            }
            $0.recordingClient.discardRecording = { discarded.withValue { $0 += 1 } }
        }

        await store.send(.view(.onAppear)) { $0.hasStarted = true }
        await store.receive(\.inner.uploadFinished)
        #expect(attempts.value == 1)
        #expect(discarded.value == 1)
    }

    @Test("업로드 1차 실패 후 재시도가 성공하면 파일을 지우고 끝난다")
    func uploadRetrySucceedsAfterFirstFailure() async {
        let attempts = LockIsolated(0)
        let discarded = LockIsolated(0)
        let store = TestStore(initialState: InterviewReportPendingFeature.State(
            recording: .fixture,
            wrapUp: .fixture
        )) {
            InterviewReportPendingFeature()
        } withDependencies: {
            $0.interviewClient.uploadInterviewVideo = { _, _, _ in
                attempts.withValue { $0 += 1 }
                if attempts.value == 1 { throw InterviewError.unexpected }
            }
            $0.recordingClient.discardRecording = { discarded.withValue { $0 += 1 } }
        }

        await store.send(.view(.onAppear)) { $0.hasStarted = true }
        await store.receive(\.inner.uploadFinished)
        #expect(attempts.value == 2)
        #expect(discarded.value == 1)
    }

    @Test("업로드가 두 번 다 실패하면 조용히 포기한다 — 사용자 통보 없이 파일만 지운다")
    func uploadGivesUpSilentlyAfterTwoFailures() async {
        let attempts = LockIsolated(0)
        let discarded = LockIsolated(0)
        let store = TestStore(initialState: InterviewReportPendingFeature.State(
            recording: .fixture,
            wrapUp: .fixture
        )) {
            InterviewReportPendingFeature()
        } withDependencies: {
            $0.interviewClient.uploadInterviewVideo = { _, _, _ in
                attempts.withValue { $0 += 1 }
                throw InterviewError.networkFailure
            }
            $0.recordingClient.discardRecording = { discarded.withValue { $0 += 1 } }
        }

        // 포기해도 delegate(에러 통보)는 없다 — exhaustive TestStore 가 여분 액션을 잡는다.
        await store.send(.view(.onAppear)) { $0.hasStarted = true }
        await store.receive(\.inner.uploadFinished)
        #expect(attempts.value == 2)
        #expect(discarded.value == 1)
    }

    @Test("업로드가 끝나기 전 홈으로 탭하면 업로드를 취소하고 파일을 지운 뒤 이탈한다")
    func goHomeCancelsInFlightUploadAndDiscards() async {
        let discarded = LockIsolated(0)
        let store = TestStore(initialState: InterviewReportPendingFeature.State(
            recording: .fixture,
            wrapUp: .fixture
        )) {
            InterviewReportPendingFeature()
        } withDependencies: {
            $0.interviewClient.uploadInterviewVideo = { _, _, _ in try await Task.never() }
            $0.recordingClient.discardRecording = { discarded.withValue { $0 += 1 } }
        }

        await store.send(.view(.onAppear)) { $0.hasStarted = true }
        await store.send(.view(.userTappedGoHome))
        await store.receive(\.delegate.goHomeRequested)
        // 업로드 effect 가 취소되지 않았다면 finish() 가 «미완 effect» 로 실패한다.
        await store.finish()
        #expect(discarded.value == 1)
    }

    @Test("녹화 산출물이 없으면 진입이 아무 effect 도 열지 않는다 — 영상 없는 리포트 경로")
    func onAppearWithoutRecordingDoesNothing() async {
        // 의존 스텁 없음 — 업로드·삭제가 불리면 unimplemented testValue 가 잡는다.
        let store = TestStore(initialState: InterviewReportPendingFeature.State()) {
            InterviewReportPendingFeature()
        }

        await store.send(.view(.onAppear))
    }
}

// MARK: - 픽스처

private extension RecordingRef {
    /// 세션 화면이 넘긴 합성 산출물 — 업로드 인자 전달만 보므로 경로·길이는 임의.
    static let fixture = RecordingRef(
        sessionId: 7, fileURL: URL(fileURLWithPath: "/tmp/interview-7.mp4"), durationSeconds: 600
    )
}

private extension InterviewVideoWrapUpSpan {
    /// 마무리 멘트 구간 — complete 바디로 그대로 실려 나간다.
    static let fixture = InterviewVideoWrapUpSpan(wrapUpStartSec: 500, wrapUpEndSec: 512)
}
