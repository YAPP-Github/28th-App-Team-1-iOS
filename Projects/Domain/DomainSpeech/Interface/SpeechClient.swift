//
//  SpeechClient.swift
//  DomainSpeechInterface
//
//  Created by 서정원 on 26/07/29.
//

import ComposableArchitecture

// @lat: [[interview#음성 캡처]]
// 마이크 캡처 + 발화 감지(검증 슬라이스) — 세션 화면이 전구간 구독해 로그로 마이크 동작을 확인한다.
// 추후 STT 는 이 struct 에 transcription 엔드포인트를 추가하고 Implementation 내부에서
// 같은 tap 버퍼를 STT 엔진에 공급한다 — Interface 소비처(Reducer)는 이벤트 매칭만 확장.
// testValue 는 여기(Interface), liveValue 는 Implementation — App/Example 만 link (D4).

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

    public init(
        startCapture: @escaping @Sendable () async -> AsyncStream<SpeechCaptureEvent>,
        stopCapture: @escaping @Sendable () async -> Void
    ) {
        self.startCapture = startCapture
        self.stopCapture = stopCapture
    }
}

extension SpeechClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: SpeechClient {
        SpeechClient(
            startCapture: unimplemented(
                "SpeechClient.startCapture", placeholder: AsyncStream { $0.finish() }
            ),
            stopCapture: unimplemented("SpeechClient.stopCapture")
        )
    }

    /// Preview 용 — 빈 스트림. 시뮬레이터 프리뷰에서 화면 흐름만 그린다.
    public static var previewValue: SpeechClient {
        SpeechClient(
            startCapture: { AsyncStream { $0.finish() } },
            stopCapture: {}
        )
    }
}

public extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}
