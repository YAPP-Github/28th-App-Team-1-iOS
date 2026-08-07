//
//  AnswerRecordingSmoke.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/08/07.
//

import AVFoundation
import ComposableArchitecture
import DomainSpeechInterface
import Foundation
import Speech
import SwiftUI

// 답변 녹음 로컬 스모크 — «면접을 완주하지 않고» 실녹음 경로(startCapture → startAnswerRecording
// → answerAudio)의 산출물만 검사한다. 서버·토큰·세션·이용권 전부 불필요, 실기기 권장.
//
// 흐름: 녹음 시작(캡처+답변 기록, 실시간 레벨 표시) → 종료 → 산출물 검사(크기·길이·피크/RMS dBFS)
//      → 재생(프로덕션 play 경로 — 재생 후 «다시 녹음» 하면 면접의 재생→녹음 전환 조건 재현)
//      → 로컬 STT(SFSpeechRecognizer) 로 서버 없이 «내 목소리 → 텍스트» 확인.
//
// 판정 기준(STT_RESET 조사용): 산출물 nil = 기록이 안 열림(캡처 미가동) ·
// 길이 ≈ 0 = 버퍼가 파일에 안 써짐(포맷 드랍 의심) · 피크 < -40 dBFS = 입력이 너무 조용함 ·
// 그 외 = 클라 녹음 체인 정상 → STT 실패는 서버 몫으로 좁혀진다.
// 녹음 중 이어폰 착탈·전화 수신으로 인터럽션(미처리 park 이슈) 시나리오도 재현해 볼 것.
struct AnswerRecordingSmoke: View {
    private enum Phase: Equatable {
        case idle
        case capturing(startedAt: Date)
        case done(Analysis)
        case failed(String)
    }

    /// 산출물 검사 결과 — 화면·콘솔 동시 출력.
    struct Analysis: Equatable {
        let bytes: Int
        let duration: Double
        let peakDb: Float
        let rmsDb: Float
        let verdict: String
    }

    @State private var phase: Phase = .idle
    @State private var liveLevel: Float?
    @State private var isSpeaking = false
    @State private var isPlaying = false
    @State private var transcript: String?
    @State private var logs: [String] = []
    @State private var captureTask: Task<Void, Never>?

    /// 검사·재생·STT 가 같은 산출물을 쓰도록 마지막 take 를 파일로 보관 — reset·화면 이탈 시 삭제.
    private static let takeURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("answer-smoke-take.m4a")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("답변 녹음 스모크").font(.title2.bold())
                Text("면접 없이 실녹음 경로 산출물만 검사합니다.\n재생 후 다시 녹음하면 면접의 재생→녹음 전환을 재현합니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                statusSection
                controlSection
                if case .done(let analysis) = phase {
                    resultSection(analysis)
                }
                if let transcript {
                    Text("로컬 STT: \(transcript)")
                        .font(.callout)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                logSection
            }
            .padding()
        }
        .onDisappear {
            captureTask?.cancel()
            Task {
                @Dependency(\.speechClient) var speechClient
                await speechClient.stopCapture()
            }
            try? FileManager.default.removeItem(at: Self.takeURL)
        }
    }

    // MARK: - 섹션

    @ViewBuilder
    private var statusSection: some View {
        switch phase {
        case .idle:
            Text("대기 중").foregroundStyle(.secondary)
        case .capturing(let startedAt):
            TimelineView(.periodic(from: startedAt, by: 0.5)) { context in
                let elapsed = Int(context.date.timeIntervalSince(startedAt))
                VStack(alignment: .leading, spacing: 6) {
                    Text("녹음 중 \(elapsed)초 — 평소 목소리로 몇 문장 말하세요")
                    // 레벨 라인이 갱신되지 않으면 tap 이 죽은 것 — 면접의 «레벨 로그 멈춤» 과 같은 신호.
                    Text(liveLevel.map { String(format: "입력 레벨 %.1f dBFS", $0) } ?? "입력 레벨 수신 대기…")
                        .monospaced()
                        .foregroundStyle(isSpeaking ? .green : .secondary)
                    ProgressView(value: normalized(liveLevel))
                }
            }
        case .done:
            Text("검사 완료 — 아래 결과 확인").foregroundStyle(.green)
        case .failed(let reason):
            Text("실패: \(reason)").foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var controlSection: some View {
        HStack {
            switch phase {
            case .idle, .failed:
                Button("녹음 시작") { startTake() }.buttonStyle(.borderedProminent)
            case .capturing:
                Button("녹음 종료 → 검사") { finishTake() }.buttonStyle(.borderedProminent)
            case .done:
                Button("재생") { playTake() }
                    .buttonStyle(.bordered)
                    .disabled(isPlaying)
                Button("로컬 STT") { transcribeTake() }.buttonStyle(.bordered)
                Button("다시 녹음") {
                    transcript = nil
                    startTake()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func resultSection(_ analysis: Analysis) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: "크기 %d bytes · 길이 %.2f초", analysis.bytes, analysis.duration))
            Text(String(format: "피크 %.1f dBFS · RMS %.1f dBFS", analysis.peakDb, analysis.rmsDb))
            Text("판정: \(analysis.verdict)").bold()
        }
        .monospaced()
        .font(.footnote)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(logs.enumerated()), id: \.offset) { _, line in
                Text(line).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 녹음 · 검사

    private func startTake() {
        phase = .capturing(startedAt: Date())
        liveLevel = nil
        isSpeaking = false
        captureTask?.cancel()
        captureTask = Task { @MainActor in
            @Dependency(\.speechClient) var speechClient
            // «다시 녹음» — 이전 스트림의 onTermination(stopCapture)이 늦게 도착해 «새» 엔진을 죽이는
            // 경합이 구현에 있다(프로덕션 재진입 용의자 — take 2 가 이 시나리오의 재현기다).
            // 스모크에선 명시 정지 + 짧은 유예로 이전 정리가 착지할 시간을 준다.
            await speechClient.stopCapture()
            try? await Task.sleep(for: .milliseconds(200))
            // 프로덕션과 같은 순서 — 캡처(엔진+tap)가 선행해야 답변 기록이 열린다.
            let events = await speechClient.startCapture()
            await speechClient.startAnswerRecording()
            log("캡처+답변 기록 시작")
            for await event in events {
                switch event {
                case .level(let decibels):
                    liveLevel = decibels
                case .speechStarted:
                    isSpeaking = true
                    log("음성 감지 시작")
                case .speechEnded:
                    isSpeaking = false
                    log("음성 감지 종료")
                case .captureFailed(let reason):
                    phase = .failed("캡처 시작 실패: \(reason)")
                    log("캡처 시작 실패: \(reason)")
                }
            }
        }
    }

    private func finishTake() {
        Task { @MainActor in
            @Dependency(\.speechClient) var speechClient
            // 순서 중요(프로덕션 제출과 동일) — 산출물 회수가 «캡처 정지보다 먼저»다.
            // for-await 취소가 먼저면 onTermination → stopCapture 가 기록을 폐기해 항상 nil 이 된다
            // (stopCapture 도 같은 이유로 회수 뒤). 캡처 effect 는 회수가 끝난 뒤에 끊는다.
            let data = await speechClient.answerAudio()
            captureTask?.cancel()
            await speechClient.stopCapture()
            guard let data else {
                phase = .failed("산출물 nil — 답변 기록이 아예 안 열렸음(캡처 미가동·파일 생성 실패)")
                log("answerAudio() == nil")
                return
            }
            do {
                try data.write(to: Self.takeURL)
                phase = .done(analyze(data))
            } catch {
                phase = .failed("take 파일 쓰기 실패: \(error.localizedDescription)")
            }
        }
    }

    /// m4a 디코드 → 길이·피크·RMS. 판정 임계는 헤더 주석의 STT_RESET 조사 기준.
    private func analyze(_ data: Data) -> Analysis {
        var duration = 0.0
        var peak: Float = 0
        var sumSquares: Double = 0
        var sampleCount = 0
        if let file = try? AVAudioFile(forReading: Self.takeURL), file.length > 0 {
            duration = Double(file.length) / file.fileFormat.sampleRate
            let capacity = AVAudioFrameCount(min(file.length, 48_000 * 120))
            if let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: capacity),
               (try? file.read(into: buffer)) != nil,
               let channels = buffer.floatChannelData {
                for channel in 0..<Int(buffer.format.channelCount) {
                    for frame in 0..<Int(buffer.frameLength) {
                        let sample = abs(channels[channel][frame])
                        peak = max(peak, sample)
                        sumSquares += Double(sample * sample)
                        sampleCount += 1
                    }
                }
            }
        }
        let peakDb = decibels(peak)
        let rmsDb = decibels(sampleCount > 0 ? Float((sumSquares / Double(sampleCount)).squareRoot()) : 0)
        let verdict: String = if duration < 0.5 {
            "빈 껍데기 — 버퍼가 파일에 안 써짐(포맷 드랍 의심)"
        } else if peakDb < -40 {
            "너무 조용함 — 입력 게인·라우팅 의심"
        } else {
            "정상 범위 — 클라 녹음 체인 무혐의, STT 실패는 서버 몫"
        }
        let analysis = Analysis(
            bytes: data.count, duration: duration, peakDb: peakDb, rmsDb: rmsDb, verdict: verdict
        )
        log(String(
            format: "산출물 %d bytes · %.2f초 · 피크 %.1f dBFS · RMS %.1f dBFS → %@",
            analysis.bytes, analysis.duration, analysis.peakDb, analysis.rmsDb, verdict
        ))
        return analysis
    }

    private func decibels(_ amplitude: Float) -> Float {
        amplitude > 0 ? max(20 * log10(amplitude), -160) : -160
    }

    /// -60…0 dBFS → 0…1 (레벨 바 표시용)
    private func normalized(_ level: Float?) -> Double {
        Double(min(max(((level ?? -60) + 60) / 60, 0), 1))
    }

    // MARK: - 재생 · 로컬 STT

    /// 프로덕션 play 경로 재사용 — 면접과 같은 재생 세션 활성화를 거친다(전환 조건 재현의 핵심).
    private func playTake() {
        Task { @MainActor in
            @Dependency(\.speechClient) var speechClient
            guard let data = try? Data(contentsOf: Self.takeURL) else { return }
            isPlaying = true
            log("재생 시작")
            for await event in await speechClient.play(data) {
                if case .failed(let reason) = event {
                    log("재생 실패: \(reason)")
                }
            }
            isPlaying = false
            log("재생 종료")
        }
    }

    private func transcribeTake() {
        transcript = "인식 중…"
        Task { @MainActor in
            do {
                transcript = try await Self.recognize(fileURL: Self.takeURL)
                log("로컬 STT 성공")
            } catch {
                transcript = "STT 실패: \(error.localizedDescription)"
                log("로컬 STT 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 파일 → 한국어 텍스트. 권한·가용성 실패는 throw 로 화면에 그대로 노출.
    private static func recognize(fileURL: URL) async throws -> String {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { throw RecognitionError.notAuthorized }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")),
              recognizer.isAvailable else {
            throw RecognitionError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            let once = OneShot()
            let request = SFSpeechURLRecognitionRequest(url: fileURL)
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    once.first { continuation.resume(throwing: error) }
                } else if let result, result.isFinal {
                    once.first { continuation.resume(returning: result.bestTranscription.formattedString) }
                }
            }
        }
    }

    private enum RecognitionError: LocalizedError {
        case notAuthorized
        case unavailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized: "음성 인식 권한이 거부됨 — 설정에서 허용 후 재시도"
            case .unavailable: "SFSpeechRecognizer(ko-KR) 사용 불가 — 네트워크·기기 설정 확인"
            }
        }
    }

    private func log(_ message: String) {
        logs.append(message)
        print("🎤 [ANSWER-SMOKE] \(message)")
    }
}

/// recognitionTask 콜백은 partial 결과로 여러 번 불린다 — continuation 이중 resume 방지.
private final class OneShot: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false

    func first(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !done else { return }
        done = true
        body()
    }
}
