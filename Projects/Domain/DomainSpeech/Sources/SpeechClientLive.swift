//
//  SpeechClientLive.swift
//  DomainSpeechImplementation
//
//  Created by 서정원 on 26/07/29.
//

import AVFoundation
import ComposableArchitecture
import DomainSpeechInterface

extension SpeechClient: @retroactive DependencyKey {
    /// 단일 매니저(캡처·재생)를 공유하는 liveValue — 세션 화면 재진입에도 같은 매니저를 쓴다.
    public static let liveValue: SpeechClient = {
        let capture = AudioCaptureManager()
        let playback = AudioPlaybackManager()
        return SpeechClient(
            startCapture: { await capture.startCapture() },
            stopCapture: { await capture.stopCapture() },
            play: { await playback.play($0) },
            playStream: { await playback.playStream(url: $0, headers: $1) },
            // 실녹음(작업 B) 전 — Example 만 번들 샘플로 오버라이드한다.
            answerAudio: { nil },
            stopPlayback: { await playback.stop() }
        )
    }()
}

/// 단일 AVAudioEngine 소유자 — start/stop 멱등. 실장치 의존이라 유닛 테스트 제외 — 실기기 로그 검증.
/// 레벨·발화 판정은 tap 콜백(직렬)에서 SpeechActivityDetector 가 수행하고, 이벤트만 스트림으로 흘린다.
actor AudioCaptureManager {
    private var engine: AVAudioEngine?
    private var continuation: AsyncStream<SpeechCaptureEvent>.Continuation?

    func startCapture() -> AsyncStream<SpeechCaptureEvent> {
        stopEngine()   // 재호출 = 기존 캡처 정지 후 재시작 (단일 구독자 계약)

        let (stream, continuation) = AsyncStream<SpeechCaptureEvent>.makeStream()
        do {
            let session = AVAudioSession.sharedInstance()
            // .playAndRecord: 추후 질문 TTS 재생과 마이크 캡처를 한 세션에서 쓴다.
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw CaptureSetupError.invalidInputFormat
            }

            let detector = SpeechActivityDetector()
            input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
                for event in detector.process(buffer) {
                    continuation.yield(event)
                }
            }
            engine.prepare()
            try engine.start()

            self.engine = engine
            self.continuation = continuation
            // 소비자가 for-await 를 취소(effect 취소)해도 엔진이 남지 않게 정지를 건다.
            continuation.onTermination = { _ in
                Task { await self.stopCapture() }
            }
        } catch {
            continuation.yield(.captureFailed(String(describing: error)))
            continuation.finish()
        }
        return stream
    }

    func stopCapture() {
        stopEngine()
        continuation?.finish()
        continuation = nil
    }

    private func stopEngine() {
        guard let engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private enum CaptureSetupError: Error {
        case invalidInputFormat
    }
}

/// 버퍼 → 레벨·발화 이벤트 변환기. tap 콜백은 직렬로 불려 상태 경쟁이 없다 (@unchecked 근거).
/// 임계·주기 상수는 실기기 튜닝 여지 — [[interview#음성 캡처]].
final class SpeechActivityDetector: @unchecked Sendable {
    /// 레벨 로그 주기.
    static let levelInterval: TimeInterval = 1.0
    /// 발화 시작 임계 (dBFS) — 상향 돌파 시 speechStarted.
    static let speechStartThreshold: Float = -35
    /// 발화 종료 임계 (dBFS) — 미만이 speechEndHold 지속되면 speechEnded (히스테리시스).
    static let speechEndThreshold: Float = -45
    static let speechEndHold: TimeInterval = 1.0
    /// 무음 바닥값 — log10(0) 방지 겸 dBFS 하한.
    static let silenceFloor: Float = -160

    private var isSpeaking = false
    private var silenceElapsed: TimeInterval = 0
    private var windowElapsed: TimeInterval = 0
    private var windowPeak: Float = -160

    func process(_ buffer: AVAudioPCMBuffer) -> [SpeechCaptureEvent] {
        guard let channelData = buffer.floatChannelData, buffer.frameLength > 0,
              buffer.format.sampleRate > 0
        else { return [] }

        let frameCount = Int(buffer.frameLength)
        let samples = channelData[0]
        var sumOfSquares: Float = 0
        for index in 0..<frameCount {
            let sample = samples[index]
            sumOfSquares += sample * sample
        }
        let rms = (sumOfSquares / Float(frameCount)).squareRoot()
        let decibels = max(20 * log10(max(rms, .leastNonzeroMagnitude)), Self.silenceFloor)
        let bufferDuration = Double(frameCount) / buffer.format.sampleRate

        var events: [SpeechCaptureEvent] = []

        // 발화 판정 — 시작은 즉시, 종료는 히스테리시스(임계 미만 1초 지속).
        if !isSpeaking, decibels > Self.speechStartThreshold {
            isSpeaking = true
            silenceElapsed = 0
            events.append(.speechStarted)
        } else if isSpeaking {
            if decibels < Self.speechEndThreshold {
                silenceElapsed += bufferDuration
                if silenceElapsed >= Self.speechEndHold {
                    isSpeaking = false
                    events.append(.speechEnded)
                }
            } else {
                silenceElapsed = 0
            }
        }

        // 레벨 로그 — 1초 윈도의 피크를 방출 (짧은 발화도 로그에 드러나게).
        windowPeak = max(windowPeak, decibels)
        windowElapsed += bufferDuration
        if windowElapsed >= Self.levelInterval {
            events.append(.level(windowPeak))
            windowElapsed = 0
            windowPeak = Self.silenceFloor
        }

        return events
    }
}
