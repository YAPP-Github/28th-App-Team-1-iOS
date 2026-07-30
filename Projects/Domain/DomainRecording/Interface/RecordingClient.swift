//
//  RecordingClient.swift
//  DomainRecordingInterface
//
//  Created by 서정원 on 26/07/28.
//

import AVFoundation
import ComposableArchitecture

// @lat: [[interview#프리뷰]]
// 전면 카메라 프리뷰 + A/V 캡처(골격) — 준비·세션 화면이 하나의 캡처 세션을 이어 쓴다.
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

/// 녹화 산출물 참조 — 필드는 작업 B(실녹화)에서 확정(파일 URL·업로드 키 등). 지금은 자리만.
public struct RecordingRef: Equatable, Sendable {
    public let sessionId: Int

    public init(sessionId: Int) {
        self.sessionId = sessionId
    }
}

/// 녹화 API 미구현 표시 — 작업 B 전까지 liveValue 가 던진다 (호출처 아직 없음).
public enum RecordingError: Error, Equatable {
    case notImplemented
}

public struct RecordingClient: Sendable {
    public var startPreview: @Sendable () async -> CameraPreviewHandle?
    public var stopPreview: @Sendable () async -> Void
    /// 녹화 시작 — 시그니처만 확정(work doc §3), 실구현·호출처는 작업 B.
    public var startRecording: @Sendable (_ sessionId: Int) async throws -> Void
    /// 녹화 종료 — 시그니처만 확정, 실구현·호출처는 작업 B.
    public var stopRecording: @Sendable () async throws -> RecordingRef

    public init(
        startPreview: @escaping @Sendable () async -> CameraPreviewHandle?,
        stopPreview: @escaping @Sendable () async -> Void,
        startRecording: @escaping @Sendable (_ sessionId: Int) async throws -> Void,
        stopRecording: @escaping @Sendable () async throws -> RecordingRef
    ) {
        self.startPreview = startPreview
        self.stopPreview = stopPreview
        self.startRecording = startRecording
        self.stopRecording = stopRecording
    }
}

extension RecordingClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: RecordingClient {
        RecordingClient(
            startPreview: unimplemented("RecordingClient.startPreview", placeholder: nil),
            stopPreview: unimplemented("RecordingClient.stopPreview"),
            startRecording: unimplemented("RecordingClient.startRecording"),
            stopRecording: unimplemented("RecordingClient.stopRecording")
        )
    }

    /// Preview 용 — 프리뷰는 nil(placeholder 유지)로 두어 시뮬레이터 프리뷰에서도 화면 흐름만 그린다.
    public static var previewValue: RecordingClient {
        RecordingClient(
            startPreview: { nil },
            stopPreview: {},
            startRecording: { _ in },
            stopRecording: { RecordingRef(sessionId: 0) }
        )
    }
}

public extension DependencyValues {
    var recordingClient: RecordingClient {
        get { self[RecordingClient.self] }
        set { self[RecordingClient.self] = newValue }
    }
}
