//
//  MicTranscriptionProbe.swift
//  DomainSpeechImplementation
//
//  Created by 서정원 on 26/08/05.
//

import AVFoundation
import Speech

/// 진단 로그 게이트 — 환경변수 `HILIT_STT_PROBE` 가 있을 때만 탐침과 재생 마커가 산다.
/// 없으면 탐침은 만들어지지도 않아 제품 경로에는 존재하지 않는 것과 같다.
enum SpeechDiagnostics {
    static let isEnabled = ProcessInfo.processInfo.environment["HILIT_STT_PROBE"] != nil

    static func log(_ message: String) {
        guard isEnabled else { return }
        print(message)
    }
}

/// 실면접 중 «마이크에 무엇이 들어오는지» 를 글로 찍는 진단 탐침 — 기본 비활성.
///
/// 쓰는 이유: 이어폰 미착용이면 면접관 TTS 가 하단 스피커로 나가고, 그동안 마이크 tap 은 계속 돈다.
/// 재생 중에 그 문장이 인식 결과로 뜨면 마이크가 TTS 를 되받는다는 뜻이고,
/// 그 소리는 세션 오디오(m4a)를 거쳐 최종 영상에까지 들어간다.
/// 재생 구간은 `AudioPlaybackManager` 가 `🔊 [TTS]` 로 찍으므로 콘솔에서 교차로 읽는다.
///
/// ⚠️ 진단 전용 — 제품의 대본은 서버 STT 가 만든다. 여기 인식 결과는 어디에도 저장하지 않는다.
final class MicTranscriptionProbe: @unchecked Sendable {
    /// 게이트가 닫혀 있으면 nil — 호출부는 옵셔널 체이닝만 하면 된다.
    static func makeIfEnabled() -> MicTranscriptionProbe? {
        SpeechDiagnostics.isEnabled ? MicTranscriptionProbe() : nil
    }

    /// tap 스레드(append)와 액터(start·stop)가 만나는 지점이라 락으로 좁게 보호한다 (@unchecked 근거).
    private let lock = NSLock()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    /// 부분 결과는 초당 여러 번 온다 — 문장이 실제로 바뀔 때만 찍어 콘솔 홍수를 막는다.
    private var lastPrinted = ""
    private var isStopped = false

    func start() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                print("🎙️ [STT] ❌ 음성 인식 권한 없음(\(status.rawValue)) — 탐침 비활성")
                return
            }
            self?.beginTask()
        }
    }

    /// 버퍼 공급 — tap 콜백에서 불린다.
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let request = request
        lock.unlock()
        request?.append(buffer)
    }

    func stop() {
        lock.lock()
        isStopped = true
        let (request, task) = (self.request, self.task)
        (self.request, self.task) = (nil, nil)
        lock.unlock()
        request?.endAudio()
        task?.cancel()
        SpeechDiagnostics.log("🎙️ [STT] ■ 탐침 정지")
    }

    // MARK: - 인식 세션

    private func beginTask() {
        lock.lock()
        guard !isStopped, let recognizer, recognizer.isAvailable else {
            lock.unlock()
            return
        }
        // 이전 세션 정리 — 재시작 경로에서 두 세션이 같은 버퍼를 먹지 않게.
        request?.endAudio()
        task?.cancel()

        let onDevice = recognizer.supportsOnDeviceRecognition
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = onDevice
        self.request = request
        lastPrinted = ""
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            self?.handle(result: result, error: error)
        }
        lock.unlock()

        SpeechDiagnostics.log("🎙️ [STT] ▶︎ 탐침 시작 — \(onDevice ? "온디바이스" : "서버 인식(약 1분마다 자동 재시작)")")
    }

    private func handle(result: SFSpeechRecognitionResult?, error: Error?) {
        lock.lock()
        if let result {
            let text = result.bestTranscription.formattedString
            if text != lastPrinted {
                lastPrinted = text
                SpeechDiagnostics.log("🎙️ [STT] \(text)")
            }
        }
        let ended = (result?.isFinal ?? false) || error != nil
        let stopped = isStopped
        lock.unlock()

        // 인식 세션은 무음·시간 제한으로 스스로 끝난다 — 면접 전체를 덮으려면 즉시 새 세션을 연다.
        guard ended, !stopped else { return }
        beginTask()
    }
}
