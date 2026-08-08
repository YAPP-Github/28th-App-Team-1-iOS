//
//  RecordingClient.swift
//  DomainRecordingInterface
//
//  Created by 서정원 on 26/07/28.
//

import AVFoundation
import ComposableArchitecture

// @lat: [[interview#프리뷰]]
// 전면 카메라 프리뷰 + 비디오 녹화 — 준비·세션 화면이 하나의 캡처 세션을 이어 쓴다.
// 캡처 세션은 «비디오 전용»(A안-2) — 마이크는 답변 오디오 엔진이 단독 소유하고,
// 정지 시점에 세션 오디오(m4a)를 사후 합성해 통짜 mp4 를 만든다.
// 소비처: 면접 준비·세션 화면(P0) — docs/work/ai-interview.md §3.
// testValue 는 여기(Interface), liveValue 는 Implementation — App/Example 만 link (D4).

/// AVCaptureSession 을 감싼 프리뷰 핸들 — TCA State 저장용.
/// Equatable 은 참조 identity(===) — 세션 객체가 바뀔 때만 뷰가 갱신된다.
public struct CameraPreviewHandle: Equatable, @unchecked Sendable {
    public let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }
}

/// 녹화 산출물 참조 — 정상 종료 시 코디네이터가 업로드 큐에 넘겨 소유권을 이전한다 (2026-08-06 스펙 §①).
public struct RecordingRef: Equatable, Sendable {
    public let sessionId: Int
    public let fileURL: URL
    public let durationSeconds: Double

    public init(sessionId: Int, fileURL: URL, durationSeconds: Double) {
        self.sessionId = sessionId
        self.fileURL = fileURL
        self.durationSeconds = durationSeconds
    }
}

/// 녹화 실패 — 실패해도 면접은 계속된다(영상 없는 리포트, 스펙 §⑥). 사유 문자열은 로그용.
public enum RecordingError: Error, Equatable {
    /// 프리뷰 세션 없음·입출력 추가 실패·기록 시작 실패.
    case startFailed(String)
    /// 진행 중 녹화 없음·기록 종료 실패·산출 파일 없음.
    case stopFailed(String)
}

public struct RecordingClient: Sendable {
    public var startPreview: @Sendable () async -> CameraPreviewHandle?
    public var stopPreview: @Sendable () async -> Void
    /// 녹화 시작 — 프리뷰 세션에 비디오 전용 무비 출력을 더한다(마이크는 엔진 소유 — 넣지 않는다, A안-2).
    /// 파일 기록이 실제로 구른 뒤(didStartRecordingTo) 반환 — 호출부가 이 시점을 세션 시계 0점으로 삼는다.
    public var startRecording: @Sendable (_ sessionId: Int) async throws -> Void
    /// 녹화 정지 + 세션 오디오(m4a) 합성 — passthrough 라 수초 내. 오디오 시작 호스트시각으로 립싱크 오프셋 보정.
    /// 오디오가 없으면 throw — 무음 영상을 만들지 않는다(스펙 §⑥, 종착은 영상 없는 리포트).
    public var stopRecording: @Sendable (_ audioFileURL: URL?, _ audioStartedAtHostSeconds: Double?) async throws -> RecordingRef
    /// 녹화 폐기 — 진행 중이면 정지 후 산출 파일 삭제(멱등·비던짐). 이탈·실패·업로드 종착(성공·포기) 공통 정리.
    public var discardRecording: @Sendable () async -> Void

    public init(
        startPreview: @escaping @Sendable () async -> CameraPreviewHandle?,
        stopPreview: @escaping @Sendable () async -> Void,
        startRecording: @escaping @Sendable (_ sessionId: Int) async throws -> Void,
        stopRecording: @escaping @Sendable (_ audioFileURL: URL?, _ audioStartedAtHostSeconds: Double?) async throws -> RecordingRef,
        discardRecording: @escaping @Sendable () async -> Void
    ) {
        self.startPreview = startPreview
        self.stopPreview = stopPreview
        self.startRecording = startRecording
        self.stopRecording = stopRecording
        self.discardRecording = discardRecording
    }
}

extension RecordingClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: RecordingClient {
        RecordingClient(
            startPreview: unimplemented("RecordingClient.startPreview", placeholder: nil),
            stopPreview: unimplemented("RecordingClient.stopPreview"),
            startRecording: unimplemented("RecordingClient.startRecording"),
            stopRecording: unimplemented("RecordingClient.stopRecording"),
            discardRecording: unimplemented("RecordingClient.discardRecording")
        )
    }

    /// Preview 용 — 프리뷰는 nil(placeholder 유지)로 두어 시뮬레이터 프리뷰에서도 화면 흐름만 그린다.
    public static var previewValue: RecordingClient {
        RecordingClient(
            startPreview: { nil },
            stopPreview: {},
            startRecording: { _ in },
            stopRecording: { _, _ in
                RecordingRef(sessionId: 0, fileURL: URL(fileURLWithPath: "/dev/null"), durationSeconds: 0)
            },
            discardRecording: {}
        )
    }
}

public extension DependencyValues {
    var recordingClient: RecordingClient {
        get { self[RecordingClient.self] }
        set { self[RecordingClient.self] = newValue }
    }
}
