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
            startRecording: { try await manager.startRecording(sessionId: $0) },
            stopRecording: { try await manager.stopRecording(audioFileURL: $0, audioStartedAtHostSeconds: $1) },
            discardRecording: { await manager.discardRecording() }
        )
    }()
}

/// 단일 AVCaptureSession 소유자 — start/stop 멱등. actor 라 세션 구성·startRunning(블로킹)이
/// 메인 스레드 밖에서 수행된다. 실장치 의존이라 유닛 테스트 제외 — 실기기 육안 검증.
actor CameraSessionManager {
    private var handle: CameraPreviewHandle?
    private var recording: ActiveRecording?
    /// 진행 중·직전 산출 파일들(비디오·오디오·합성본) — stop 이후에도 discard 가 지울 수 있게 유지한다.
    /// 갈아끼우지 않고 누적한다 — 새 녹화가 배열을 덮어쓰면 직전 합성본이 추적에서 사라져 누수된다.
    private var lastFileURLs: [URL] = []
    /// start/stop 은 await 을 품는다 — 액터가 그 사이 다른 호출을 들여보내므로 «구간» 을 플래그로 잠근다.
    private var isStarting = false
    private var isStopping = false
    /// 시작 «구간» 의 기록 파일 — 아직 `recording` 에 서지 않았어도 폐기 대상에서 제외해야 한다.
    private var startingFileURL: URL?
    /// 정지·시작 중 들어온 폐기 요청 — 그때 지워도 진행 중인 작업이 산출물을 다시 만든다. 그 작업이 끝날 때 처리한다.
    private var discardRequested = false

    private struct ActiveRecording {
        let output: AVCaptureMovieFileOutput
        let delegate: MovieRecordingDelegate
        let url: URL
        let sessionId: Int
    }

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

    /// A안-2(스펙 §①) — 프리뷰 세션에 **비디오 전용** 무비 출력을 더해 기록한다(마이크는 엔진 소유 — 넣지 않는다).
    /// didStartRecordingTo 후 반환 — 호출부가 이 시점을 세션 시계 0점으로 삼는다(타임라인 정렬).
    func startRecording(sessionId: Int) async throws {
        // 멱등 — `recording` 세팅은 아래 await 뒤라, 플래그로 시작 «구간» 까지 가드를 넓힌다.
        // (넓히지 않으면 동시 호출이 둘 다 통과해 무비 출력 두 개가 같은 파일에 기록된다.)
        guard recording == nil, !isStarting else { return }
        isStarting = true
        defer {
            isStarting = false
            startingFileURL = nil
        }
        guard let session = handle?.session else {
            throw RecordingError.startFailed("프리뷰 세션 없음")
        }
        let output = try attachMovieOutput(to: session)

        let videoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("interview-video-\(sessionId).mp4")
        try? FileManager.default.removeItem(at: videoURL)
        startingFileURL = videoURL   // 아직 추적 배열에 없다 — 진행 중 폐기의 삭제 대상에서 제외하기 위한 표시.

        let delegate = MovieRecordingDelegate()
        output.startRecording(to: videoURL, recordingDelegate: delegate)
        do {
            try await delegate.waitUntilStarted()
        } catch {
            detachOutput(output)
            throw RecordingError.startFailed(String(describing: error))
        }
        recording = ActiveRecording(output: output, delegate: delegate, url: videoURL, sessionId: sessionId)
        track(videoURL)
        // 시작을 기다리는 동안 폐기 요청이 도착했으면 방금 선 기록을 즉시 되돌린다.
        // 남겨 두면 고아 ActiveRecording 이 되어 이후 startRecording 이 전부 no-op 이 되고,
        // stopRecording 은 폐기된 세션의 ref 를 돌려준다(엉뚱한 세션에 업로드).
        if discardRequested {
            await rollbackStart(videoURL: videoURL)
            throw RecordingError.startFailed("녹화 폐기됨")
        }
    }

    /// 프리뷰 세션에 비디오 전용 무비 출력을 붙인다 — 비트레이트 캡 포함.
    private func attachMovieOutput(to session: AVCaptureSession) throws -> AVCaptureMovieFileOutput {
        // 캡처 세션이 오디오 세션을 재구성해 엔진 tap 을 끊는 것을 막는다 (스파이크 1차 실패 교훈 — 마이크 공유 금지).
        session.automaticallyConfiguresApplicationAudioSession = false

        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        }
        let output = AVCaptureMovieFileOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw RecordingError.startFailed("무비 출력 추가 실패")
        }
        session.addOutput(output)
        if let connection = output.connection(with: .video),
           output.availableVideoCodecTypes.contains(.h264) {
            output.setOutputSettings([
                AVVideoCodecKey: AVVideoCodecType.h264,
                // 상반신 고정 화면이라 2.5Mbps 로 충분 — 12분 ≈ 220MB (기본 ~8-10Mbps 는 700MB+, 업로드 병목).
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2_500_000]
            ], for: connection)
        }
        session.commitConfiguration()
        return output
    }

    /// 시작 대기 중 도착한 폐기 요청 처리 — 방금 선 기록을 정지·삭제한다.
    private func rollbackStart(videoURL: URL) async {
        startingFileURL = nil   // 이 기록이 폐기 대상 — 제외 목록에서 뺀다.
        await teardownRecording()
        if isStopping {
            // 정지·합성이 아직 도는 중 — 이 파일만 지우고, 나머지 폐기는 그쪽 defer 몫으로 남긴다.
            removeTracked(videoURL)
        } else {
            discardRequested = false
            purgeTrackedFiles()
        }
    }

    /// 정지 + 합성(스펙 §①) — 비디오 정지 → 오디오를 호스트시각 오프셋만큼 밀어 insert → passthrough export.
    /// 오디오 없음·합성 실패는 throw — 무음 영상을 만들지 않는다(종착은 영상 없는 리포트).
    func stopRecording(audioFileURL: URL?, audioStartedAtHostSeconds: Double?) async throws -> RecordingRef {
        // 어느 실패 경로로 빠지든 12분치 m4a 가 남지 않도록 «가드보다 먼저» 추적에 편입한다.
        track(audioFileURL)
        guard let recording else { throw RecordingError.stopFailed("진행 중인 녹화 없음") }
        isStopping = true
        defer {
            isStopping = false
            // 정지·합성 중 들어온 폐기 요청은 여기서 처리 — 산출물이 다 만들어진 뒤라야 실제로 지워진다.
            if discardRequested {
                // 그 사이 시작된 «새» 녹화 소속 파일은 제외 — 기록 중인 mp4 를 지우면 그 녹화가 깨진다.
                purgeTrackedFiles(excluding: activeRecordingFileURLs)
                // 시작 중인 녹화가 있으면 요청은 그 꼬리(startRecording)가 마저 처리한다.
                if !isStarting { discardRequested = false }
            }
        }
        recording.output.stopRecording()
        self.recording = nil
        do {
            try await recording.delegate.waitUntilFinished()
        } catch {
            detachOutput(recording.output)
            throw RecordingError.stopFailed(String(describing: error))
        }
        detachOutput(recording.output)
        guard FileManager.default.fileExists(atPath: recording.url.path) else {
            throw RecordingError.stopFailed("비디오 파일 없음")
        }
        guard let audioFileURL, let audioStartedAtHostSeconds else {
            throw RecordingError.stopFailed("세션 오디오 없음")
        }
        let mergedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("interview-recording-\(recording.sessionId).mp4")
        track(recording.url, mergedURL)
        let duration = try await compose(
            videoURL: recording.url,
            videoStartedAt: recording.delegate.startedAtHostSeconds,
            audioURL: audioFileURL,
            audioStartedAt: audioStartedAtHostSeconds,
            to: mergedURL
        )
        // 원본 임시 파일은 합성 성공 후에만 정리 — 합성본만 남긴다.
        removeTracked(recording.url, audioFileURL)
        // 합성 중 폐기를 요청받았으면 산출물은 곧 defer 가 지운다 — 지워질 파일을 참조로 돌려주지 않는다.
        guard !discardRequested else { throw RecordingError.stopFailed("녹화 폐기됨") }
        return RecordingRef(sessionId: recording.sessionId, fileURL: mergedURL, durationSeconds: duration)
    }

    func discardRecording() async {
        // 정지·시작이 도는 중이면 표시만 — 지금 지워도 그 작업이 산출물을 다시 만든다.
        // 요청은 진행 중인 작업의 꼬리(stop 의 defer / start 의 tail)가 받아 처리한다.
        guard !isStopping, !isStarting else {
            discardRequested = true
            return
        }
        await teardownRecording()
        discardRequested = false
        purgeTrackedFiles()
    }

    /// 진행 중인 기록을 즉시 정지·해제 — 파일 정리 범위는 경우마다 달라 호출부 몫으로 둔다.
    private func teardownRecording() async {
        guard let recording else { return }
        recording.output.stopRecording()
        self.recording = nil
        try? await recording.delegate.waitUntilFinished()
        detachOutput(recording.output)
    }

    /// 진행 중·시작 중인 녹화 소속 파일 — 폐기 대상에서 제외한다(기록 중인 mp4 를 지우면 그 녹화가 깨진다).
    private var activeRecordingFileURLs: [URL] {
        [recording?.url, startingFileURL].compactMap { $0 }
    }

    /// 산출 파일 추적 편입 — 중복 없이 누적한다(덮어쓰면 직전 산출물이 추적에서 사라져 누수).
    private func track(_ urls: URL?...) {
        for case let url? in urls where !lastFileURLs.contains(url) {
            lastFileURLs.append(url)
        }
    }

    /// 삭제 + 추적 해제 — 합성 성공 후 원본 정리처럼 «지웠으니 추적에서도 뺀다» 용도.
    private func removeTracked(_ urls: URL...) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
            lastFileURLs.removeAll { $0 == url }
        }
    }

    /// 추적 중인 산출 파일 삭제 — 폐기의 실체. `excluding` 은 삭제도 추적 해제도 하지 않는다.
    private func purgeTrackedFiles(excluding kept: [URL] = []) {
        for url in lastFileURLs where !kept.contains(url) {
            try? FileManager.default.removeItem(at: url)
        }
        lastFileURLs = lastFileURLs.filter { kept.contains($0) }
    }

    /// AVMutableComposition 합성 — 스파이크 2차 검증 구조 + 립싱크 오프셋 보정. 반환은 합성본 길이(초).
    private func compose(
        videoURL: URL, videoStartedAt: Double?, audioURL: URL, audioStartedAt: Double, to mergedURL: URL
    ) async throws -> Double {
        try? FileManager.default.removeItem(at: mergedURL)
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first
        else { throw RecordingError.stopFailed("합성 트랙 없음") }

        let composition = AVMutableComposition()
        let videoDuration = try await videoAsset.load(.duration)
        guard let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw RecordingError.stopFailed("합성 트랙 생성 실패") }
        try compositionVideo.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero)
        // 전면 카메라 회전 승계 — 없으면 합성본이 눕는다 (스파이크 2차 교훈).
        compositionVideo.preferredTransform = try await videoTrack.load(.preferredTransform)

        // 립싱크 오프셋(스펙 §①): 오디오는 비디오보다 늦게 시작한다 — 그 차만큼 뒤에 insert.
        // 음수(오디오가 먼저)면 그만큼 오디오 머리를 잘라 t=0 insert.
        let offset = audioStartedAt - (videoStartedAt ?? audioStartedAt)
        let audioDuration = try await audioAsset.load(.duration)
        if offset >= 0 {
            try compositionAudio.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                of: audioTrack,
                at: CMTime(seconds: offset, preferredTimescale: 600)
            )
        } else {
            let head = CMTime(seconds: -offset, preferredTimescale: 600)
            try compositionAudio.insertTimeRange(
                CMTimeRange(start: head, duration: audioDuration - head),
                of: audioTrack,
                at: .zero
            )
        }

        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw RecordingError.stopFailed("export 세션 생성 실패")
        }
        if #available(iOS 18, *) {
            try await export.export(to: mergedURL, as: .mp4)
        } else {
            export.outputURL = mergedURL
            export.outputFileType = .mp4
            await withCheckedContinuation { continuation in
                export.exportAsynchronously { continuation.resume() }
            }
            // status 로 판정 — 실패인데 error 가 비어 오는 경우가 있다 (스파이크 검증 구조).
            guard export.status == .completed else {
                throw RecordingError.stopFailed(String(describing: export.error))
            }
        }
        return videoDuration.seconds.isFinite ? videoDuration.seconds : 0
    }

    /// 녹화 종료 후 무비 출력을 세션에서 제거 — 프리뷰는 계속 돈다(리포트 대기 배경 등 무영향).
    private func detachOutput(_ output: AVCaptureMovieFileOutput) {
        guard let session = handle?.session else { return }
        session.beginConfiguration()
        session.removeOutput(output)
        session.commitConfiguration()
    }
}

/// AVCaptureFileOutputRecordingDelegate 를 async 로 브릿지 — 시작·종료 콜백을 continuation 으로 전달.
/// 콜백 스레드와 액터가 만나는 지점이라 락으로 좁게 보호한다 (@unchecked 근거).
final class MovieRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var didStart = false
    private var finishResult: Result<Void, Error>?
    private var startContinuation: CheckedContinuation<Void, Error>?
    private var finishContinuation: CheckedContinuation<Void, Error>?
    private var startedAt: Double?

    /// 비디오 기록 시작 호스트시각(초) — 합성 시 오디오 오프셋 보정 기준 (스펙 §①). 읽기도 락으로 보호.
    var startedAtHostSeconds: Double? {
        lock.lock()
        defer { lock.unlock() }
        return startedAt
    }

    func waitUntilStarted() async throws {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            defer { lock.unlock() }
            if didStart { return continuation.resume() }
            // 시작 콜백 없이 이미 끝났으면 기록은 서지 않은 것 — 성공 플래그여도 대기하지 않는다(콜백 경로와 대칭).
            switch finishResult {
            case .none: startContinuation = continuation
            case .success: continuation.resume(throwing: RecordingError.startFailed("기록 시작 전 종료"))
            case let .failure(error): continuation.resume(throwing: error)
            }
        }
    }

    func waitUntilFinished() async throws {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            defer { lock.unlock() }
            if let finishResult { return continuation.resume(with: finishResult) }
            finishContinuation = continuation
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        lock.lock()
        defer { lock.unlock() }
        didStart = true
        startedAt = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        startContinuation?.resume()
        startContinuation = nil
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        lock.lock()
        defer { lock.unlock() }
        // 정상 정지도 error 에 성공 플래그를 실어 오는 경우가 있다 — 플래그가 진실.
        let succeeded = ((error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? (error == nil)
        let result: Result<Void, Error> = succeeded ? .success(()) : .failure(error ?? RecordingError.stopFailed("원인 미상"))
        finishResult = result
        startContinuation?.resume(throwing: error ?? RecordingError.startFailed("기록 시작 전 종료"))
        startContinuation = nil
        finishContinuation?.resume(with: result)
        finishContinuation = nil
    }
}
