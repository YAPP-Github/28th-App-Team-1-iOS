//
//  RecordingClientLive.swift
//  DomainRecordingImplementation
//
//  Created by 서정원 on 26/07/28.
//

import AVFoundation
import ComposableArchitecture
import DomainRecordingInterface

extension RecordingClient: @retroactive DependencyKey {
    /// 단일 CameraSessionManager 를 공유하는 liveValue — 준비·세션 화면이 같은 캡처 세션을 이어 쓴다.
    /// static let: 접근마다 매니저가 새로 만들어지면 멱등 공유가 깨진다.
    public static let liveValue: RecordingClient = {
        let manager = CameraSessionManager()
        return RecordingClient(
            startPreview: { await manager.startPreview() },
            stopPreview: { await manager.stopPreview() },
            startRecording: { _ in throw RecordingError.notImplemented },
            stopRecording: { throw RecordingError.notImplemented }
        )
    }()
}

/// 단일 AVCaptureSession 소유자 — start/stop 멱등. actor 라 세션 구성·startRunning(블로킹)이
/// 메인 스레드 밖에서 수행된다. 실장치 의존이라 유닛 테스트 제외 — 실기기 육안 검증.
actor CameraSessionManager {
    private var handle: CameraPreviewHandle?

    func startPreview() -> CameraPreviewHandle? {
        if let handle { return handle }
        guard
            // 준비 화면 게이트와 별개로 계약(권한 미허용 → nil)을 여기서도 강제 — notDetermined 로
            // 세션을 구성하면 검은 프레임 + 시스템 권한 프롬프트가 엉뚱한 시점에 뜬다.
            AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return nil }   // 권한 미허용·시뮬레이터·장치 없음 — 호출부가 placeholder 로 진행

        let session = AVCaptureSession()
        session.beginConfiguration()
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return nil
        }
        session.addInput(input)
        session.commitConfiguration()
        session.startRunning()

        let handle = CameraPreviewHandle(session: session)
        self.handle = handle
        return handle
    }

    func stopPreview() {
        handle?.session.stopRunning()
        handle = nil
    }
}
