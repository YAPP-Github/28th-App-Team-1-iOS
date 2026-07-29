//
//  InterviewSessionFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import DomainRecordingInterface

// @lat: [[interview#세션]]
@Reducer
public struct InterviewSessionFeature {
    static let clockTick: Duration = .seconds(1)
    static let exitUnlockSeconds = 8 * 60
    static let hardCapSeconds = 12 * 60
    static let finalCountdownSeconds = 10
    /// 8분 해금 안내 토스트 유지 시간.
    static let exitNoticeHold: Duration = .seconds(3)
    /// 답변 정리(mock) 유지 시간 — 다음 질문 재생 시작까지의 임시 지연.
    /// TODO(작업 C): InterviewClient.submitAnswer 응답(다음 질문 TTS 시작)으로 asking 복귀를 교체.
    static let processingAnswerHold: Duration = .seconds(2)

    @ObservableState
    public struct State: Equatable {
        /// 턴 표시 상태 — View 는 이 값(+토스트)만 그린다. 질문 텍스트는 노출하지 않는다(TTS-only).
        public enum Phase: Equatable, Sendable {
            case asking
            case answering
            /// 답변 확정 직후 — «답변을 정리하고 있어요» (PRD §3.5 칩 3종). 되돌리지 않는다.
            case processingAnswer
            /// 세션 상한 임박 — 빨간 «N초» 칩 초읽기, 상태 칩 없음
            case finalCountdown
        }

        public enum Toast: Equatable, Sendable {
            case exitUnlocked
            case timeExpired

            public var message: String {
                switch self {
                case .exitUnlocked: "8분이 경과되어 면접을 종료할 수 있어요"
                case .timeExpired: "시간이 경과되어 면접을 종료합니다"
                }
            }

            public var hasTail: Bool { self == .exitUnlocked }
        }

        public var phase: Phase = .asking
        /// 세션 경과 시간(초) — 상단 칩 m:ss.
        public var elapsedSeconds = 0
        /// 8:00 경과 — «면접 종료하기» 노출.
        public var isExitAvailable = false
        public var toast: Toast?
        /// 종료 확인 모달 (Figma ExitConfirm) — 화면 위 오버레이라 별도 destination 없이 Bool.
        public var isExitConfirmPresented = false
        /// 8분 전 중도 이탈 경고 모달 (Interview_EarlyExitWarning) — 차감 사실만 알린다 (PRD §3.7).
        public var isEarlyExitWarningPresented = false
        /// onAppear 재진입 가드 — 세션 시계 effect 중복 실행 방지.
        public var hasStarted = false
        /// 프리뷰 핸들 — 코디네이터가 준비 화면의 핸들을 시드해 첫 프레임부터 프리뷰가 붙는다
        /// (nil 시드면 onAppear 멱등 재요청이 채울 때까지 placeholder). 재요청은 백스톱으로 유지.
        public var previewHandle: CameraPreviewHandle?

        /// 최종 카운트다운 잔여 초 — 상한까지 남은 시간.
        public var countdownRemaining: Int {
            max(0, InterviewSessionFeature.hardCapSeconds - elapsedSeconds)
        }

        public init(previewHandle: CameraPreviewHandle? = nil) {
            self.previewHandle = previewHandle
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedAnswerComplete
            /// 좌상단 X — 8분 전엔 중도 이탈 경고, 8분 후엔 종료 확인 모달. (이탈 동선 표기는 «협의 가능» — 임시 X)
            case userTappedClose
            /// 중도 이탈 경고 «나가기» — 차감 감수하고 이탈. 서버가 그때까지의 턴을 보존한다.
            case userTappedLeaveInterview
            case userTappedExit
            case userTappedContinueInterview
            /// 종료 확인 모달 «마치기» — 즉시 종료, 지금까지 답변으로 분석.
            case userTappedFinishInterview
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// 프리뷰 핸들 확보 — 실패(권한 회수 등)면 nil, placeholder 로 진행.
            case previewStarted(CameraPreviewHandle?)
            /// 세션 시계 1초 경과.
            case clockTicked
            /// 질문 TTS 재생 완료 — answering 전환. TODO: SpeechClient 도입 시 effect 가 방출.
            case questionPlaybackFinished
            /// 8분 해금 토스트 유지 시간 경과.
            case exitNoticeExpired
            /// 답변 정리(mock) 지연 경과 — 질문 듣기로 복귀. TODO(작업 C): submitAnswer 응답으로 대체.
            case processingAnswerFinished
            /// STT 연속 실패·네트워크 단절 감지 — 실패 화면 전환은 코디네이터 몫.
            /// TODO: SpeechClient confidence 집계·NetworkClient 에러에서 방출 (P3, work doc §6-e).
            case failureDetected(InterviewFailureKind)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case finished
            /// 중도 이탈·세션 무결성 훼손 — 그때까지의 턴은 서버가 보존한다(차감 D1, PRD §3.7). 클라는 이탈 신호만.
            case aborted
            /// STT·네트워크 실패 — 코디네이터가 실패 화면으로 전환.
            case failed(InterviewFailureKind)
        }
    }

    private enum CancelID { case clock, toast, processing }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.recordingClient) var recordingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)
            case let .inner(action):
                return reduceInner(&state, action)
            case .delegate:
                return .none
            }
        }
    }

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            guard !state.hasStarted else { return .none }
            state.hasStarted = true
            // TODO: SpeechClient — 요약 질문 TTS 재생 시작(완료 시 questionPlaybackFinished) ·
            //       실녹화(RecordingClient.startRecording)는 작업 B — 지금은 프리뷰 승계만.
            return .merge(
                .run { send in
                    await send(.inner(.previewStarted(recordingClient.startPreview())))
                },
                .run { send in
                    for await _ in clock.timer(interval: Self.clockTick) {
                        await send(.inner(.clockTicked))
                    }
                }
                .cancellable(id: CancelID.clock)
            )

        case .userTappedAnswerComplete:
            guard state.phase == .answering else { return .none }
            // 누르면 그 즉시 확정 (PRD §3.5) — 침묵 판정을 기다리지 않는다.
            state.phase = .processingAnswer
            return .run { send in
                try await clock.sleep(for: Self.processingAnswerHold)
                await send(.inner(.processingAnswerFinished))
            }
            .cancellable(id: CancelID.processing, cancelInFlight: true)

        case .userTappedClose:
            if state.isExitAvailable {
                state.isExitConfirmPresented = true
            } else {
                state.isEarlyExitWarningPresented = true
            }
            return .none

        case .userTappedLeaveInterview:
            state.isEarlyExitWarningPresented = false
            return .merge(
                .cancel(id: CancelID.clock),
                .cancel(id: CancelID.toast),
                .cancel(id: CancelID.processing),
                .send(.delegate(.aborted))
            )

        case .userTappedExit:
            guard state.isExitAvailable else { return .none }
            state.isExitConfirmPresented = true
            return .none

        case .userTappedContinueInterview:
            state.isExitConfirmPresented = false
            state.isEarlyExitWarningPresented = false
            return .none

        case .userTappedFinishInterview:
            return finishSession(&state)
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .previewStarted(handle):
            state.previewHandle = handle
            return .none

        case .clockTicked:
            return reduceClockTick(&state)

        case .questionPlaybackFinished:
            guard state.phase == .asking else { return .none }
            state.phase = .answering
            return .none

        case .exitNoticeExpired:
            guard state.toast == .exitUnlocked else { return .none }
            state.toast = nil
            return .none

        case .processingAnswerFinished:
            // finalCountdown 등이 먼저 phase 를 덮었으면 무시 — 카운트다운을 되돌리지 않는다.
            guard state.phase == .processingAnswer else { return .none }
            state.phase = .asking
            return .none

        case let .failureDetected(kind):
            state.isExitConfirmPresented = false
            return .merge(
                .cancel(id: CancelID.clock),
                .cancel(id: CancelID.toast),
                .cancel(id: CancelID.processing),
                .send(.delegate(.failed(kind)))
            )
        }
    }

    /// 세션 시계 1초 진행 — 8:00 해금, 상한 10초 전 최종 카운트다운, 상한 도달 시 종료.
    private func reduceClockTick(_ state: inout State) -> Effect<Action> {
        state.elapsedSeconds += 1

        if state.elapsedSeconds >= Self.hardCapSeconds {
            return finishSession(&state)
        }

        if state.elapsedSeconds >= Self.hardCapSeconds - Self.finalCountdownSeconds {
            if state.phase != .finalCountdown {
                state.phase = .finalCountdown
                state.toast = .timeExpired   // 카운트다운 동안 상시 유지 — 만료 타이머 없음.
                return .cancel(id: CancelID.toast)
            }
            return .none
        }

        if state.elapsedSeconds == Self.exitUnlockSeconds {
            state.isExitAvailable = true
            // 해금과 함께 낡은 차감 경고는 닫는다 — 안내는 아래 해금 토스트가 잇는다.
            state.isEarlyExitWarningPresented = false
            state.toast = .exitUnlocked
            return .run { send in
                try await clock.sleep(for: Self.exitNoticeHold)
                await send(.inner(.exitNoticeExpired))
            }
            .cancellable(id: CancelID.toast, cancelInFlight: true)
        }

        return .none
    }

    /// 세션 종료 공통 — 시계·토스트 정리 후 완료 통보. 화면 전환(보고서·닫기)은 상위 몫.
    private func finishSession(_ state: inout State) -> Effect<Action> {
        state.isExitConfirmPresented = false
        return .merge(
            .cancel(id: CancelID.clock),
            .cancel(id: CancelID.toast),
            .cancel(id: CancelID.processing),
            .send(.delegate(.finished))
        )
    }
}
