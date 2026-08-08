//
//  AVConcurrencySpike.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/08/05.
//

import AVFoundation
import AVKit
import SwiftUI

// A안-2(스펙 §결정 요약) 게이트 스파이크 — 마이크는 AVAudioEngine 이 «단독 소유»하고, 캡처 세션은
// 비디오 전용으로 녹화한 뒤 정지 시점에 두 트랙을 사후 합성한다. 클라이언트 계층을 거치지 않는 raw AVFoundation.
//
// 1차 C안(캡처세션 마이크 병행)은 mp4 무음으로 실패(2026-08-05) — 마이크는 엔진 단독 소유.
//
// 합격 기준(전부 충족해야 A안-2 확정, 하나라도 실패 → 스펙 재개정):
// ① 녹화 중 레벨(dBFS)이 계속 갱신된다 — 비디오 전용 캡처 세션이 엔진 tap 을 끊지 않는다.
// ② «말하기 테스트»(AVSpeechSynthesizer) 재생 중에도 레벨·녹화가 지속된다.
// ③ 합성 mp4(spike-merged.mp4) 재생 시 영상과 «음성이 모두» 확인된다 — 핵심 판정.
// ④ m4a(spike-audio.m4a) 단독 재생이 정상이다.
struct AVConcurrencySpike: View {
    @State private var driver = SpikeDriver()
    @State private var showsPlayer = false

    var body: some View {
        NavigationStack {
            List {
                Section("상태") {
                    Text(driver.status)
                    Text("입력 레벨: \(driver.levelText) dBFS").monospaced()
                }
                Section("조작") {
                    Button("① 동시 구동 시작") { driver.start() }
                    Button("② 말하기 테스트 (재생 공존)") { driver.speak() }
                    Button("③ 정지 + 합성 + 산출물 확인") { driver.stop() }
                }
                if let result = driver.result {
                    Section("산출물") {
                        Text(result)
                        Button("합성 mp4 재생") { showsPlayer = true }
                            .disabled(driver.mergedURL == nil)
                        Button("m4a 재생") { driver.playAnswer() }
                    }
                }
            }
            .navigationTitle("A/V 사후 합성 스파이크")
            .sheet(isPresented: $showsPlayer) {
                if let url = driver.mergedURL {
                    VideoPlayer(player: AVPlayer(url: url))
                }
            }
        }
    }
}

@Observable
final class SpikeDriver {
    var status = "대기"
    var levelText = "—"
    var result: String?
    var mergedURL: URL?

    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let engine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var answerFile: AVAudioFile?
    private var videoURL: URL?
    private var audioURL: URL?
    private var answerPlayer: AVAudioPlayer?
    private let movieDelegate = SpikeMovieDelegate()

    func start() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            guard startVideoRecording() else { return }   // 실패 사유는 내부에서 status 에 남긴다.
            try startEngineTap()
            status = "🔴 비디오 녹화 + tap 동시 구동 중 — 말을 하면 레벨이 움직여야 함"
        } catch {
            status = "❌ 시작 실패: \(error)"
        }
    }

    /// 비디오 전용 캡처 세션 구성 + 녹화 시작 — 마이크 입력은 넣지 않는다(엔진이 단독 소유).
    /// 실패하면 status 에 사유를 남기고 false.
    private func startVideoRecording() -> Bool {
        // 오디오 세션 재구성만 막아 엔진 tap 을 보호한다.
        captureSession.automaticallyConfiguresApplicationAudioSession = false
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        }
        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput)
        else {
            status = "❌ 카메라 입력 실패 (권한·실기기 확인)"
            captureSession.commitConfiguration()
            return false
        }
        captureSession.addInput(cameraInput)
        guard captureSession.canAddOutput(movieOutput) else {
            status = "❌ 무비 출력 추가 실패"
            captureSession.commitConfiguration()
            return false
        }
        captureSession.addOutput(movieOutput)
        captureSession.commitConfiguration()
        captureSession.startRunning()

        let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent("spike-video.mp4")
        try? FileManager.default.removeItem(at: videoURL)
        movieOutput.startRecording(to: videoURL, recordingDelegate: movieDelegate)
        self.videoURL = videoURL
        return true
    }

    /// 엔진 tap — 마이크 단독 소유자로서 레벨 갱신 + m4a 전구간 기록 (실구현과 같은 구도).
    private func startEngineTap() throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("spike-audio.m4a")
        try? FileManager.default.removeItem(at: audioURL)
        answerFile = try AVAudioFile(forWriting: audioURL, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount
        ], commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        self.audioURL = audioURL
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            try? self.answerFile?.write(from: buffer)
            guard let channel = buffer.floatChannelData, buffer.frameLength > 0 else { return }
            var sum: Float = 0
            for index in 0..<Int(buffer.frameLength) { sum += channel[0][index] * channel[0][index] }
            let mean = (sum / Float(buffer.frameLength)).squareRoot()
            let decibels = max(20 * log10(max(mean, .leastNonzeroMagnitude)), -160)
            Task { @MainActor in self.levelText = String(format: "%.1f", decibels) }
        }
        engine.prepare()
        try engine.start()
    }

    func speak() {
        let utterance = AVSpeechUtterance(string: "지금 재생 중에도 레벨과 녹화가 이어져야 합니다")
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        synthesizer.speak(utterance)
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        answerFile = nil   // 파일 닫힘 — 합성 입력이 되려면 먼저 닫혀야 한다.
        status = "정지 — 무비 파일 마무리 대기 중"
        // 합성은 didFinishRecording 이후에만 안전하다(moov 미기록 파일은 트랙을 못 읽음) → 완료 시그널 브릿지.
        movieDelegate.onFinish = { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.captureSession.stopRunning()
                if let error {
                    self.status = "❌ 녹화 마무리 실패: \(error)"
                }
                await self.merge()
            }
        }
        movieOutput.stopRecording()
    }

    func playAnswer() {
        guard let audioURL else { return }
        answerPlayer = try? AVAudioPlayer(contentsOf: audioURL)
        answerPlayer?.play()
    }

    /// 비디오 트랙(spike-video.mp4) + 오디오 트랙(spike-audio.m4a) → passthrough export 로 spike-merged.mp4.
    /// A안-2 의 유일한 추가 비용 지점이라 소요 시간을 계측해 결과에 노출한다.
    @MainActor
    private func merge() async {
        guard let videoURL, let audioURL else { return }
        status = "합성 중…"
        let startedAt = Date()
        let mergedURL = FileManager.default.temporaryDirectory.appendingPathComponent("spike-merged.mp4")
        try? FileManager.default.removeItem(at: mergedURL)
        var note: String
        do {
            let composition = AVMutableComposition()
            let videoAsset = AVURLAsset(url: videoURL)
            let audioAsset = AVURLAsset(url: audioURL)
            guard
                let videoSource = try await videoAsset.loadTracks(withMediaType: .video).first,
                let audioSource = try await audioAsset.loadTracks(withMediaType: .audio).first,
                let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            else {
                throw SpikeMergeError.missingTrack
            }
            let videoDuration = try await videoAsset.load(.duration)
            let audioDuration = try await audioAsset.load(.duration)
            try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoSource, at: .zero)
            // 오디오는 .zero 삽입 — 녹화와 tap 을 같은 시점에 시작했으므로 오프셋 보정 없이 맞물린다.
            try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration), of: audioSource, at: .zero)
            // 전면 카메라 회전 정보 승계 — 없으면 합성본이 누워서 «영상 이상» 으로 오판된다.
            videoTrack.preferredTransform = try await videoSource.load(.preferredTransform)

            guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
                throw SpikeMergeError.exportSessionUnavailable
            }
            if #available(iOS 18, *) {
                try await export.export(to: mergedURL, as: .mp4)
            } else {
                export.outputURL = mergedURL
                export.outputFileType = .mp4
                await withCheckedContinuation { continuation in
                    export.exportAsynchronously { continuation.resume() }
                }
                if export.status != .completed { throw export.error ?? SpikeMergeError.exportFailed }
            }
            self.mergedURL = mergedURL
            note = "합성 OK — 위 버튼으로 영상+음성 동시 확인"
        } catch {
            note = "❌ 합성 실패: \(error)"
        }
        let elapsed = Date().timeIntervalSince(startedAt)
        result = """
        video \(fileSize(videoURL)) bytes / audio \(fileSize(audioURL)) bytes / merged \(fileSize(self.mergedURL)) bytes
        합성 소요 \(String(format: "%.2f", elapsed))s — \(note)
        """
        status = "정지 완료"
    }

    private func fileSize(_ url: URL?) -> Int {
        url.flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int } ?? 0
    }
}

enum SpikeMergeError: Error {
    case missingTrack
    case exportSessionUnavailable
    case exportFailed
}

final class SpikeMovieDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    /// 무비 파일 마무리 완료 신호 — 합성 시작 시점을 잡기 위한 최소 브릿지.
    var onFinish: ((Error?) -> Void)?

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        print("⛳️ [SPIKE] didFinishRecording error=\(String(describing: error))")
        onFinish?(error)
    }
}
