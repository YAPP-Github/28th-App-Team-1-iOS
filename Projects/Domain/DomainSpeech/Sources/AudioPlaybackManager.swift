//
//  AudioPlaybackManager.swift
//  DomainSpeechImplementation
//
//  Created by 서정원 on 26/08/02.
//

import AVFoundation
import DomainSpeechInterface

/// 단일 재생 소유자 — 질문 TTS(chunked 스트림)와 요약 질문·마무리 멘트(base64 mp3)를 액터가 재생한다.
/// 스트림 소비자의 for-await 취소는 재생을 멈추지 않는다 — 마무리 멘트 fire-and-forget 의 근거.
/// 정지는 `stop()`(멱등) 뿐이라 이탈·실패 전환의 코디네이터 호출로만 끊긴다.
/// 실장치 의존이라 유닛 테스트 제외 — Example·실기기 스모크로 검증(AudioCaptureManager 와 같은 관례).
actor AudioPlaybackManager {
    private var dataPlayer: AVAudioPlayer?
    private var dataPlayerDelegate: DataPlayerDelegate?
    private var streamPlayer: AVPlayer?
    private var streamObservers: [any NSObjectProtocol] = []
    private var streamStatusObservation: NSKeyValueObservation?

    /// base64 디코딩된 mp3 재생 — 완료/실패 1회 방출 후 스트림이 닫힌다. 재호출은 기존 재생 교체.
    func play(_ data: Data) -> AsyncStream<PlaybackEvent> {
        stop()
        let (stream, continuation) = AsyncStream<PlaybackEvent>.makeStream()
        do {
            try activatePlaybackSession()
            let player = try AVAudioPlayer(data: data)
            let delegate = DataPlayerDelegate { event in
                continuation.yield(event)
                continuation.finish()
            }
            player.delegate = delegate
            guard player.play() else {
                throw PlaybackSetupError.playRefused
            }
            dataPlayer = player
            dataPlayerDelegate = delegate
        } catch {
            continuation.yield(.failed(String(describing: error)))
            continuation.finish()
        }
        return stream
    }

    /// 질문 TTS 점진 재생 — chunked(Content-Length 없음)라 전부 받고 재생하지 않는다
    /// (AVURLAsset 헤더 주입 → AVPlayer). 중간 실패는 HTTP 로 안 잡힌다 — 실패 노티·status 관찰이
    /// 유일한 감지 지점이고, 재시도(같은 questionId 재호출 = TTS 재생성)는 소비처 몫.
    func playStream(url: URL, headers: [String: String]) -> AsyncStream<PlaybackEvent> {
        stop()
        let (stream, continuation) = AsyncStream<PlaybackEvent>.makeStream()
        do {
            try activatePlaybackSession()
        } catch {
            continuation.yield(.failed(String(describing: error)))
            continuation.finish()
            return stream
        }
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        let center = NotificationCenter.default
        streamObservers = [
            center.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: nil) { _ in
                continuation.yield(.finished)
                continuation.finish()
            },
            center.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: nil) { note in
                let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                continuation.yield(.failed(error.map { String(describing: $0) } ?? "재생 중단"))
                continuation.finish()
            }
        ]
        streamStatusObservation = item.observe(\.status) { item, _ in
            guard item.status == .failed else { return }
            continuation.yield(.failed(item.error.map { String(describing: $0) } ?? "재생 준비 실패"))
            continuation.finish()
        }
        player.play()
        streamPlayer = player
        return stream
    }

    /// 재생 정지 — 미재생 상태에서 불러도 안전(멱등). 진행 중이던 스트림은 이벤트 없이 닫히지 않고
    /// 그대로 남지만, 소비 effect 는 화면 전환으로 이미 취소된 뒤라 누수가 없다.
    func stop() {
        dataPlayer?.stop()
        dataPlayer = nil
        dataPlayerDelegate = nil
        streamPlayer?.pause()
        streamPlayer = nil
        for observer in streamObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        streamObservers = []
        streamStatusObservation?.invalidate()
        streamStatusObservation = nil
    }

    /// 캡처(AudioCaptureManager)와 같은 `.playAndRecord` — 재생과 마이크가 한 세션을 공유한다.
    private func activatePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    private enum PlaybackSetupError: Error {
        case playRefused
    }
}

/// AVAudioPlayerDelegate 브리지 — 완료/디코딩 실패를 클로저 한 번으로 좁힌다.
/// 콜백 시점의 가변 상태가 없고 continuation 은 Sendable — @unchecked 근거.
private final class DataPlayerDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    private let onEvent: @Sendable (PlaybackEvent) -> Void

    init(onEvent: @escaping @Sendable (PlaybackEvent) -> Void) {
        self.onEvent = onEvent
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onEvent(flag ? .finished : .failed("재생이 완료되지 못했어요"))
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        onEvent(.failed(error.map { String(describing: $0) } ?? "오디오 디코딩 실패"))
    }
}
