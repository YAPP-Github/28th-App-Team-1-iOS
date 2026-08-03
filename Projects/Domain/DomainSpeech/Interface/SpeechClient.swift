//
//  SpeechClient.swift
//  DomainSpeechInterface
//
//  Created by 서정원 on 26/07/29.
//

import ComposableArchitecture
import Foundation

// @lat: [[interview#음성 캡처]]
// 마이크 캡처 + 발화 감지(검증 슬라이스) + 서버 TTS 재생(질문=스트림, 요약·마무리=base64 mp3).
// 추후 STT 는 이 struct 에 transcription 엔드포인트를 추가하고 Implementation 내부에서
// 같은 tap 버퍼를 STT 엔진에 공급한다 — Interface 소비처(Reducer)는 이벤트 매칭만 확장.
// testValue 는 여기(Interface), liveValue 는 Implementation — App/Example 만 link (D4).

/// 질문·멘트 재생 이벤트 — 재생 주체는 Implementation 의 액터라 리듀서 effect 가 취소돼도 재생은 지속된다.
public enum PlaybackEvent: Equatable, Sendable {
    case finished
    /// 디코딩·스트림 중단 등 — 사유는 로그·재시도 판단용.
    case failed(String)
}

/// 마이크 캡처 이벤트 — 검증 로그·추후 침묵 판정(PRD §3.6)의 씨앗.
public enum SpeechCaptureEvent: Equatable, Sendable {
    /// 입력 레벨 dBFS(−160…0) — 1초 주기. 마이크 생존 확인용.
    case level(Float)
    /// 레벨이 발화 임계를 상향 돌파.
    case speechStarted
    /// 발화 중 레벨이 종료 임계 미만으로 1초 지속.
    case speechEnded
    /// 엔진 시작 실패(권한 거부·세션 구성 실패 등) — 방출 후 스트림이 종료된다.
    case captureFailed(String)
}

public struct SpeechClient: Sendable {
    /// 마이크 캡처 시작 — 단일 구독자 가정(세션 화면 1곳). 재호출 시 기존 캡처를 정지 후 재시작.
    public var startCapture: @Sendable () async -> AsyncStream<SpeechCaptureEvent>
    /// 캡처 정지 + 엔진 해제 — 미실행 상태에서 불러도 안전(멱등).
    public var stopCapture: @Sendable () async -> Void
    /// base64 디코딩된 mp3 재생(요약 질문·마무리 멘트). 재호출 시 기존 재생을 교체(단일 재생).
    public var play: @Sendable (Data) async -> AsyncStream<PlaybackEvent>
    /// 질문 TTS 점진 재생 — chunked 스트림이라 AVPlayer 로 URL 재생(Authorization 헤더 동봉).
    /// `InterviewAudioStream` 을 직접 받지 않는 건 DomainInterview Interface 의존을 만들지 않기 위해 —
    /// 호출부(Feature)가 url·headers 로 풀어 전달한다.
    public var playStream: @Sendable (_ url: URL, _ headers: [String: String]) async -> AsyncStream<PlaybackEvent>
    /// 답변 구간 오디오 seam — 실녹음(작업 B) 전 liveValue 는 nil. Example 만 번들 샘플 주입.
    public var answerAudio: @Sendable () async -> Data?
    /// 재생 정지(멱등) — 흐름 이탈·실패 전환에서 코디네이터가 캡처와 함께 부른다.
    /// 정상 종료(리포트 대기 전환)는 부르지 않는다 — 마무리 멘트 재생을 살리기 위해.
    public var stopPlayback: @Sendable () async -> Void

    public init(
        startCapture: @escaping @Sendable () async -> AsyncStream<SpeechCaptureEvent>,
        stopCapture: @escaping @Sendable () async -> Void,
        play: @escaping @Sendable (Data) async -> AsyncStream<PlaybackEvent>,
        playStream: @escaping @Sendable (_ url: URL, _ headers: [String: String]) async -> AsyncStream<PlaybackEvent>,
        answerAudio: @escaping @Sendable () async -> Data?,
        stopPlayback: @escaping @Sendable () async -> Void
    ) {
        self.startCapture = startCapture
        self.stopCapture = stopCapture
        self.play = play
        self.playStream = playStream
        self.answerAudio = answerAudio
        self.stopPlayback = stopPlayback
    }
}

extension SpeechClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: SpeechClient {
        SpeechClient(
            startCapture: unimplemented(
                "SpeechClient.startCapture", placeholder: AsyncStream { $0.finish() }
            ),
            stopCapture: unimplemented("SpeechClient.stopCapture"),
            play: unimplemented(
                "SpeechClient.play", placeholder: AsyncStream { $0.finish() }
            ),
            playStream: unimplemented(
                "SpeechClient.playStream", placeholder: AsyncStream { $0.finish() }
            ),
            answerAudio: unimplemented("SpeechClient.answerAudio", placeholder: nil),
            stopPlayback: unimplemented("SpeechClient.stopPlayback")
        )
    }

    /// Preview 용 — 캡처는 빈 스트림, 재생은 즉시 완료. 시뮬레이터 프리뷰에서 화면 흐름만 그린다.
    public static var previewValue: SpeechClient {
        SpeechClient(
            startCapture: { AsyncStream { $0.finish() } },
            stopCapture: {},
            play: { _ in
                AsyncStream {
                    $0.yield(.finished)
                    $0.finish()
                }
            },
            playStream: { _, _ in
                AsyncStream {
                    $0.yield(.finished)
                    $0.finish()
                }
            },
            answerAudio: { nil },
            stopPlayback: {}
        )
    }
}

public extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}
