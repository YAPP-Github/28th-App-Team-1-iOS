//
//  TapFileRecorderTests.swift
//  DomainSpeechTests
//
//  Created by 서정원 on 26/08/06.
//

import AVFoundation
import Testing

@testable import DomainSpeechImplementation

// 세션 전구간 m4a 는 영상과 «사후» 합성된다 — 파일 길이가 곧 립싱크이고 답변 startSec 정렬의 기준이다.
// 그래서 AI 발화 구간 무음화는 버퍼를 «건너뛰는» 게 아니라 «같은 길이의 0 을 쓰는» 것이어야 한다.
// 리듀서 테스트(FeatureInterview)는 토글이 걸리는 «순서»만 고정하므로, 길이 보존은 여기서 닫는다.
struct TapFileRecorderTests {
    private static let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private static let framesPerBuffer: AVAudioFrameCount = 4_800   // 0.1초
    private static let bufferCount = 10

    @Test("무음 구간도 같은 길이를 기록한다 — 건너뛰면 이후 오디오가 통째로 앞으로 밀린다")
    func mutedBuffersPreserveTimelineLength() throws {
        let written = AVAudioFramePosition(Self.framesPerBuffer) * AVAudioFramePosition(Self.bufferCount)
        let continuous = try recordedFrames(mutingFrom: nil)
        let halfMuted = try recordedFrames(mutingFrom: Self.bufferCount / 2)

        // 무음이 길이를 갉아먹지 않았고(1행), 그 «같음» 이 양쪽이 함께 비어서 성립한 게 아니다(2행).
        #expect(halfMuted == continuous)
        #expect(continuous >= written)
    }

    @Test("버퍼 없이 끝난 기록은 nil 과 함께 파일도 지운다 — 유일 파일명은 다음 begin 이 덮어쓰지 않는다")
    func finishWithoutBuffersRemovesFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tap-recorder-\(UUID().uuidString).m4a")
        let recorder = TapFileRecorder()
        recorder.begin(url: url, format: Self.format)
        try #require(FileManager.default.fileExists(atPath: url.path))   // begin 이 파일을 실제로 만들었는가

        #expect(recorder.finishKeepingFile() == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    /// 같은 개수의 tap 버퍼를 흘려보내고 결과 m4a 의 프레임 길이를 돌려준다.
    /// `mutingFrom` 번째 버퍼부터 무음 토글 — nil 이면 전 구간 유성음(대조군).
    ///
    /// 절대 프레임 수가 아니라 «대조군과 같은가» 로 단언하는 이유: AAC 는 인코더 지연·프레임
    /// 경계 패딩이 붙어 입력 총합과 딱 떨어지지 않는다. 두 실행이 같은 경로로 같은 개수를 쓰므로
    /// 패딩은 양쪽에서 상쇄되고, 남는 차이는 «무음이 길이를 갉아먹었나» 하나뿐이다.
    private func recordedFrames(mutingFrom: Int?) throws -> AVAudioFramePosition {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tap-recorder-\(UUID().uuidString).m4a")
        let recorder = TapFileRecorder()
        recorder.begin(url: url, format: Self.format)

        for index in 0..<Self.bufferCount {
            if index == mutingFrom { recorder.setMuted(true) }
            recorder.write(tone(), at: AVAudioTime(hostTime: mach_absolute_time()))
        }

        let finished = try #require(recorder.finishKeepingFile())
        defer { try? FileManager.default.removeItem(at: finished.0) }
        return try AVAudioFile(forReading: finished.0).length
    }

    /// 무음과 구분되는 입력 버퍼 — 진폭이 0 이면 «무음을 기록했다» 와 «입력이 원래 0 이었다» 가 섞인다.
    private func tone() -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: Self.format, frameCapacity: Self.framesPerBuffer)!
        buffer.frameLength = Self.framesPerBuffer
        let samples = buffer.floatChannelData![0]
        for frame in 0..<Int(Self.framesPerBuffer) {
            samples[frame] = sin(Float(frame) * 0.05) * 0.5
        }
        return buffer
    }
}
