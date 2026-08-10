//
//  InterviewFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import DomainSpeechInterface

// @lat: [[interview#코디네이터]]
/// Part 2 면접 흐름 코디네이터 — 도메인 내부 화면 전환(준비 → 세션 → 실패)만 담당한다.
/// 화면들은 delegate 로만 신호를 올리고, 이 리듀서가 screen 을 갈아끼운다.
/// 종료엔 화면이 없다 — 산출물을 업로드 큐에 접수(소유권 이전)하고 장치를 정지한 뒤 즉시 홈으로 통보한다(스펙 ①).
/// 흐름 밖(보고서 진입·닫기)은 다시 delegate 로 AppFeature 에 올린다 (D1 — cross-feature 조립은 AppFeature).
/// 세션 payload(sessionId — 온보딩 분석 산출물)는 `State(sessionId:)` 로 받는다 — AppFeature 배선은 작업 D.
@Reducer
public struct InterviewFeature {
    /// 면접 흐름 하위 화면 — push 스택이 아니라 전면 교체라 StackState 대신 enum destination.
    @Reducer
    public enum Screen {
        case readiness(InterviewReadinessFeature)
        case session(InterviewSessionFeature)
        case failure(InterviewFailureFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var screen: Screen.State
        /// 온보딩 분석이 만든 세션 id — 흐름 내내 같은 세션을 쓴다.
        public let sessionId: Int
        /// 종료 신호 first-wins — 정상 종료엔 갈아탈 화면이 없어 finished 후에도 screen 이 .session 에 머문다.
        /// 늦은 두 번째 finished/aborted 를 case 가드만으로 거를 수 없어, 이 플래그가 이중 통보·재접수를 막는다.
        public var isClosing = false

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
            /// 면접 정상 종료(산출물 업로드 큐 접수 완료 → 홈으로) — 보고서 전환·dismiss 는 AppFeature 몫.
            case finished
            /// 면접 흐름 이탈(중단 폐기·실패 화면 X) — dismiss 는 AppFeature 몫.
            case closed
        }
    }

    @Dependency(\.interviewVideoUploadQueue) var uploadQueue
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
                // 준비 화면의 READY 페이로드(요약 질문)와 프리뷰 핸들을 세션 상태로 시드 —
                // 요약 질문은 첫 턴 재생(작업 C), 핸들은 비동기 재요청을 기다리는 동안
                // placeholder 로 떨어지는 깜빡임 방지. 재요청(onAppear)은 백스톱으로 유지된다.
                guard case let .readiness(readiness) = state.screen,
                      case let .ready(summaryQuestion) = readiness.questionPrep
                else { return .none }
                state.screen = .session(InterviewSessionFeature.State(
                    sessionId: state.sessionId,
                    summaryQuestion: summaryQuestion,
                    previewHandle: readiness.previewHandle
                ))
                return .none

            case .screen(.readiness(.delegate(.backRequested))):
                // 준비 화면 뒤로가기 = 흐름 이탈. 아직 면접 전이라 서버 제출 없이 장치만 정리하고 나간다
                // (세션은 서버에 남지만 답변 0개 — 재진입 동선은 홈의 «이어서 진행» 몫, home-account §4).
                return stopCaptureDevicesThenNotifyClosed()

            case .screen(.readiness(.delegate(.prepFailed))):
                state.screen = .failure(InterviewFailureFeature.State(kind: .questionPrep))
                return stopCaptureDevicesAndPlayback()

            case let .screen(.session(.delegate(.finished(ref, wrapUp)))):
                // 세션 effect 는 이 전환으로 취소되지 않는다(Scope-on-enum) — 「정지+합성」 구간에서 뒤늦은
                // 두 번째 통보가 도달할 수 있어, 이미 종료를 확정했으면 무시한다(업로드 재접수·이중 통보 방지).
                guard case .session = state.screen, !state.isClosing else { return .none }
                state.isClosing = true
                // 산출물 소유권은 큐로 — enqueue(파일 이동+저널, 밀리초) 뒤 장치를 정지하고 즉시 홈(스펙 ①).
                // 전환 중 유일하게 `discardRecording()` 을 부르지 않는 경로다 — 파일은 이제 큐 것이다.
                return .run { send in
                    if let ref {
                        await uploadQueue.enqueue(ref.sessionId, ref.fileURL, wrapUp)
                    }
                    await recordingClient.stopPreview()
                    await speechClient.stopCapture()
                    await send(.delegate(.finished))
                }

            case .screen(.session(.delegate(.aborted))):
                // finished 와 같은 창(위 주석) — 뒤늦게 도달하면 폐기가 **큐에 넘긴 파일**을 지운다.
                guard case .session = state.screen, !state.isClosing else { return .none }
                state.isClosing = true
                return stopCaptureDevicesThenNotifyClosed()

            case let .screen(.session(.delegate(.failed(kind)))):
                // 화면 교체 전이라 case 가드만으론 «종료 확정 뒤 도착한 실패» 를 못 막는다 — isClosing 이 막는다
                // (뚫리면 실패 헬퍼의 discardRecording 이 큐에 넘긴 파일을 지운다).
                guard case .session = state.screen, !state.isClosing else { return .none }
                state.screen = .failure(InterviewFailureFeature.State(kind: kind))
                return stopCaptureDevicesAndPlayback()

            case .screen(.failure(.delegate(.closeRequested))):
                return stopCaptureDevicesThenNotifyClosed()

            case .screen, .delegate:
                return .none
            }
        }
    }

    /// 실패 전환 공통 — 캡처에 더해 진행 중 질문 재생도 끊는다(실패 화면 뒤에서 소리가 이어지지 않게).
    /// 진행 중 녹화가 있으면 정지·폐기한다(스펙 §① 실패 = 즉시 정지 + 파일 폐기) — 멱등이라 준비 화면 경로에선 no-op.
    private func stopCaptureDevicesAndPlayback() -> Effect<Action> {
        .run { _ in
            await recordingClient.discardRecording()
            await recordingClient.stopPreview()
            await speechClient.stopCapture()
            await speechClient.stopPlayback()
        }
    }

    /// 흐름 이탈 공통 — 정지(재생 포함) 완료 후 상위 통보. merge 로 두면 상위 dismiss 가 정지 effect 를
    /// 취소할 수 있어(작업 D: ifLet 해제 시 자식 effect 취소) 순서를 보장한다.
    /// 진행 중 녹화가 있으면 정지·폐기한다(스펙 §① BACK_EXIT = 즉시 정지 + 파일 폐기) — 준비 화면 경로에선 no-op.
    private func stopCaptureDevicesThenNotifyClosed() -> Effect<Action> {
        .run { send in
            await recordingClient.discardRecording()
            await recordingClient.stopPreview()
            await speechClient.stopCapture()
            await speechClient.stopPlayback()
            await send(.delegate(.closed))
        }
    }
}

extension InterviewFeature.Screen.State: Equatable {}
