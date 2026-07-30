//
//  InterviewFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import DomainRecordingInterface
import DomainSpeechInterface

// @lat: [[interview#코디네이터]]
/// Part 2 면접 흐름 코디네이터 — 도메인 내부 화면 전환(준비 → 세션 → 실패/종료)만 담당한다.
/// 화면들은 delegate 로만 신호를 올리고, 이 리듀서가 screen 을 갈아끼운다.
/// 흐름 밖(보고서 진입·닫기)은 다시 delegate 로 AppFeature 에 올린다 (D1 — cross-feature 조립은 AppFeature).
/// TODO: 세션 payload(sessionId — 온보딩 분석 산출물) 수신은 AppFeature 배선 시 (work doc §2).
@Reducer
public struct InterviewFeature {
    /// 면접 흐름 하위 화면 — push 스택이 아니라 전면 교체라 StackState 대신 enum destination.
    @Reducer(state: .equatable)
    public enum Screen {
        case readiness(InterviewReadinessFeature)
        case session(InterviewSessionFeature)
        case failure(InterviewFailureFeature)
        case reportPending(InterviewReportPendingFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var screen: Screen.State
        /// 온보딩 분석이 만든 세션 id — 실패 화면의 «다시 시작하기» 재진입에도 같은 세션을 쓴다.
        public let sessionId: Int

        public init(sessionId: Int) {
            self.sessionId = sessionId
            self.screen = .readiness(InterviewReadinessFeature.State(sessionId: sessionId))
        }
    }

    public enum Action {
        case screen(Screen.Action)
        case delegate(Delegate)

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 면접 정상 종료(리포트 대기 화면에서 홈으로) — 보고서 전환·dismiss 는 AppFeature 몫.
            case finished
            /// 면접 흐름 이탈(중단 폐기·실패 화면 X) — dismiss 는 AppFeature 몫.
            case closed
        }
    }

    @Dependency(\.recordingClient) var recordingClient
    @Dependency(\.speechClient) var speechClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.screen, action: \.screen) {
            Screen.body
        }
        Reduce { state, action in
            switch action {
            case .screen(.readiness(.delegate(.startRequested))):
                // 준비 화면의 프리뷰 핸들을 시드 — 세션 화면이 비동기 재요청을 기다리는 동안
                // placeholder 로 떨어지는 깜빡임 방지. 재요청(onAppear)은 백스톱으로 유지된다.
                guard case let .readiness(readiness) = state.screen else { return .none }
                state.screen = .session(
                    InterviewSessionFeature.State(previewHandle: readiness.previewHandle)
                )
                return .none

            case .screen(.readiness(.delegate(.prepFailed))):
                state.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
                return stopCaptureDevices()

            case .screen(.session(.delegate(.finished))):
                state.screen = .reportPending(InterviewReportPendingFeature.State())
                return stopCaptureDevices()

            case .screen(.reportPending(.delegate(.goHomeRequested))):
                return .send(.delegate(.finished))

            case .screen(.session(.delegate(.aborted))):
                return stopCaptureDevicesThenNotifyClosed()

            case let .screen(.session(.delegate(.failed(kind)))):
                state.screen = .failure(InterviewFailureFeature.State(kind: kind))
                return stopCaptureDevices()

            case .screen(.failure(.delegate(.restartRequested))):
                state.screen = .readiness(InterviewReadinessFeature.State(sessionId: state.sessionId))
                return .none

            case .screen(.failure(.delegate(.closeRequested))):
                return stopCaptureDevicesThenNotifyClosed()

            case .screen, .delegate:
                return .none
            }
        }
    }

    /// 캡처 화면(준비·세션)을 떠나는 전환 공통 — 카메라 프리뷰·마이크 캡처 정지(둘 다 멱등).
    /// 실패 화면 «다시 시작하기» 재진입은 Readiness onAppear(카메라)·세션 onAppear(마이크)가 다시 켠다.
    private func stopCaptureDevices() -> Effect<Action> {
        .run { _ in
            await recordingClient.stopPreview()
            await speechClient.stopCapture()
        }
    }

    /// 흐름 이탈 공통 — 정지 완료 후 상위 통보. merge 로 두면 상위 dismiss 가 정지 effect 를
    /// 취소할 수 있어(작업 D: ifLet 해제 시 자식 effect 취소) 순서를 보장한다.
    private func stopCaptureDevicesThenNotifyClosed() -> Effect<Action> {
        .run { send in
            await recordingClient.stopPreview()
            await speechClient.stopCapture()
            await send(.delegate(.closed))
        }
    }
}
