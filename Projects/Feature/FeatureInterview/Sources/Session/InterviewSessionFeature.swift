//
//  InterviewSessionFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import DomainSpeechInterface
import Foundation
import OSLog

// @lat: [[interview#세션]]
@Reducer
public struct InterviewSessionFeature {
    static let clockTick: Duration = .seconds(1)
    static let exitUnlockSeconds = 8 * 60
    static let hardCapSeconds = 12 * 60
    static let finalCountdownSeconds = 10
    /// 8분 해금 안내 토스트 유지 시간.
    static let exitNoticeHold: Duration = .seconds(3)
    /// 랩업 임계(8:45) — 이후 제출은 isWrapUp=true 로 서버에 마무리 국면을 알린다.
    static let wrapUpThresholdSeconds = 8 * 60 + 45
    /// 503(aiTemporarilyUnavailable) 백오프 — 같은 제출을 지연 후 재시도(서버에 아무것도 저장 안 됨 계약).
    static let submissionRetryDelays: [Duration] = [.seconds(1), .seconds(3)]

    /// 진행 중 질문 — 요약 질문(턴 0)과 submitAnswer 응답(NextQuestion)을 한 형으로 접는다.
    public struct ActiveQuestion: Equatable, Sendable {
        public var questionId: Int
        public var turnLevel: Int
        public var isLast: Bool

        init(questionId: Int, turnLevel: Int, isLast: Bool) {
            self.questionId = questionId
            self.turnLevel = turnLevel
            self.isLast = isLast
        }

        init(_ question: SummaryQuestion) {
            self.init(questionId: question.questionId, turnLevel: question.turn?.turnLevel ?? 0, isLast: false)
        }

        init(_ question: NextQuestion) {
            self.init(questionId: question.questionId, turnLevel: question.turn?.turnLevel ?? 1, isLast: question.isLast ?? false)
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 턴 표시 상태 — View 는 이 값(+토스트)만 그린다. 질문 텍스트는 노출하지 않는다(TTS-only).
        public enum Phase: Equatable, Sendable {
            case asking
            case answering
            /// 답변 확정 직후 — «답변을 정리하고 있어요» (PRD §3.5 칩 3종). 되돌리지 않는다.
            /// 제출형 종료(마치기·상한)도 응답까지 이 phase 로 대기를 표현한다.
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

        /// 답변 제출·질문 스트림의 경로 파라미터 — 준비 화면과 같은 세션이다.
        public let sessionId: Int
        /// READY 폴링이 동봉한 요약 질문 — 첫 asking 재생(base64 mp3)에 쓴다.
        public let summaryQuestion: SummaryQuestion

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

        /// 진행 중 질문 — 요약 질문으로 시작해 submitAnswer 응답으로 갈아탄다.
        public var currentQuestion: ActiveQuestion
        /// 시간 마킹(초 — 세션 시계 스냅샷, 실녹화 전 근사값). 제출 시 Double 로 변환된다.
        public var questionAudioStartedAt: Int?
        public var questionAudioEndedAt: Int?
        public var answerStartedAt: Int?
        /// 중복 제출 가드 (ANSWER_ALREADY_SUBMITTED 예방).
        public var isSubmitting = false
        /// 질문 재생 실패 1회 재시도 가드 — 질문이 바뀌면 리셋.
        public var hasRetriedPlayback = false
        /// 제출 비행 중 12:00 도달 — 새 질문을 여는 대신 응답 수신 후 HARD_CAP 마감으로 잇는다.
        public var hardCapReachedWhileSubmitting = false
        /// 실녹화 시작 성공 — 종료 시 stopRecording·업로드 배선 여부 (실패 = 영상 없는 리포트).
        public var hasRecording = false
        /// 마무리 멘트 재생 중 — 시계는 계측용으로만 돌고 해금·상한 로직은 잠근다.
        public var isWrappingUp = false
        /// 마무리 멘트 재생 시작 시점(녹화 타임라인 초).
        public var wrapUpStartedAt: Int?
        /// 계측 완료된 마무리 구간 — recordingStopped 가 delegate 로 실어 보낸다.
        public var wrapUpSpan: InterviewVideoWrapUpSpan?
        /// 정지+합성 진행 중 — 재진입(두 번째 stopRecording)과 종료·이탈 입력을 함께 막는다.
        public var isFinishing = false

        /// 최종 카운트다운 잔여 초 — 상한까지 남은 시간.
        public var countdownRemaining: Int {
            max(0, InterviewSessionFeature.hardCapSeconds - elapsedSeconds)
        }

        public init(
            sessionId: Int,
            summaryQuestion: SummaryQuestion,
            previewHandle: CameraPreviewHandle? = nil
        ) {
            self.sessionId = sessionId
            self.summaryQuestion = summaryQuestion
            self.previewHandle = previewHandle
            self.currentQuestion = ActiveQuestion(summaryQuestion)
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
            /// 중도 이탈 경고 «나가기» — 차감 감수하고 이탈. BACK_EXIT 를 최선 노력 제출 후 서버가 턴을 보존한다.
            case userTappedLeaveInterview
            case userTappedExit
            case userTappedContinueInterview
            /// 종료 확인 모달 «마치기» — MANUAL_END 제출을 거쳐 종료, 지금까지 답변으로 분석.
            case userTappedFinishInterview
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// 프리뷰 핸들 확보 — 실패(권한 회수 등)면 nil, placeholder 로 진행.
            case previewStarted(CameraPreviewHandle?)
            /// 녹화 시작 종료(성공 여부) — 이 시점이 세션 시계 0점·첫 질문 재생(타임라인 정렬, 스펙 §①).
            case recordingStarted(Bool)
            /// 마무리 멘트 재생 종료(실패 포함) — 구간을 확정하고 녹화를 정지한다.
            case wrapUpPlaybackFinished
            /// 녹화 정지 종료 — 실패면 nil(영상 없는 리포트).
            case recordingStopped(RecordingRef?)
            /// 세션 시계 1초 경과.
            case clockTicked
            /// 질문 TTS 재생 완료 — answering 전환.
            case questionPlaybackFinished
            /// 질문 TTS 재생 실패 — 같은 질문 1회 재시도(TTS 재생성) 후 네트워크 실패 처리.
            case questionPlaybackFailed
            /// 8분 해금 토스트 유지 시간 경과.
            case exitNoticeExpired
            /// 답변 제출 성공 — 다음 질문 재생 또는 세션 종료(endType) 분기.
            case answerSubmitted(AnswerResult)
            /// 답변 제출 실패(503 재시도 소진 포함) — 종료됐던 세션이면 리포트 대기로, 그 외 실패 화면.
            case answerSubmissionFailed(InterviewError)
            /// 8분 전 이탈의 최선 노력 제출 종료(성공·실패 무관) — 이탈을 진행한다.
            case earlyExitSubmissionFinished
            /// STT 연속 실패·네트워크 단절 감지 — 실패 화면 전환은 코디네이터 몫.
            case failureDetected(InterviewFailureKind)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 정상 종료 — 녹화 산출물(nil = 영상 없는 리포트)과 마무리 멘트 구간(nil = 멘트 없음)을 함께 넘긴다.
            /// 업로드 배선은 코디네이터 몫.
            case finished(RecordingRef?, InterviewVideoWrapUpSpan?)
            /// 중도 이탈·세션 무결성 훼손 — 그때까지의 턴은 서버가 보존한다(차감 D1, PRD §3.7). 클라는 이탈 신호만.
            case aborted
            /// STT·네트워크 실패 — 코디네이터가 실패 화면으로 전환.
            case failed(InterviewFailureKind)
        }
    }

    private enum CancelID { case clock, toast, submission, micCapture, playback }

    /// 마이크 검증 로그 — 실기기에서 레벨·발화 감지를 눈으로 확인하는 용도 (docs/superpowers/specs/2026-07-29-mic-capture-design.md).
    static let micLogger = Logger(subsystem: "FeatureInterview", category: "MicCapture")
    /// 질문 재생 실패 사유 로그 — 재시도 판단은 리듀서가 하고, 원문은 여기만 남긴다.
    static let playbackLogger = Logger(subsystem: "FeatureInterview", category: "Playback")
    /// 녹화 시작·정지 실패 사유 로그 — 실패해도 면접은 계속되므로(영상 없는 리포트) 원문은 여기만 남는다.
    static let recordingLogger = Logger(subsystem: "FeatureInterview", category: "Recording")

    @Dependency(\.continuousClock) var clock
    @Dependency(\.interviewClient) var interviewClient
    @Dependency(\.recordingClient) var recordingClient
    @Dependency(\.speechClient) var speechClient

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

}

// MARK: - Reduce (본체 밖 extension — 타입 본문 길이 규칙, 접근은 파일 내 private)

extension InterviewSessionFeature {
    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        // 마무리 멘트 계측·정지+합성 중(= 종료 확정 후)엔 종료·이탈 입력을 닫는다. 열어 두면 재제출이 409 를
        // 부르고, 그 sessionAlreadyEnded 경로와 뒤이은 wrapUpPlaybackFinished·recordingStopped 가 각각 종료를
        // 통보해 delegate 가 두 번 나간다 — 먼저 도착한 빈 결과가 코디네이터의 first-wins 로 진짜 ref 를 덮는다.
        if state.isWrappingUp || state.isFinishing {
            switch action {
            case .userTappedClose, .userTappedExit, .userTappedFinishInterview, .userTappedLeaveInterview:
                return .none
            case .onAppear, .userTappedAnswerComplete, .userTappedContinueInterview:
                break
            }
        }

        switch action {
        case .onAppear:
            guard !state.hasStarted else { return .none }
            state.hasStarted = true
            let sessionId = state.sessionId
            return .merge(
                .run { send in
                    await send(.inner(.previewStarted(recordingClient.startPreview())))
                },
                // 타임라인 정렬(스펙 §①): 녹화 시작 완료 → 세션 시계 0점 → 첫 질문. 시계·재생은 recordingStarted 가 연다.
                .run { send in
                    do {
                        try await recordingClient.startRecording(sessionId)
                        await send(.inner(.recordingStarted(true)))
                    } catch {
                        Self.recordingLogger.error("녹화 시작 실패: \(String(describing: error))")
                        await send(.inner(.recordingStarted(false)))
                    }
                }
            )

        case .userTappedAnswerComplete:
            guard state.phase == .answering, !state.isSubmitting else { return .none }
            // 누르면 그 즉시 확정 (PRD §3.5) — 침묵 판정을 기다리지 않는다.
            state.phase = .processingAnswer
            return submitCurrentAnswer(&state, endType: nil)

        case .userTappedClose:
            if state.isExitAvailable {
                state.isExitConfirmPresented = true
            } else {
                state.isEarlyExitWarningPresented = true
            }
            return .none

        case .userTappedLeaveInterview:
            state.isEarlyExitWarningPresented = false
            // 최선 노력 1회 제출(재시도·오디오 없음, 스펙 §5.3) — 실패해도 이탈은 진행한다.
            let submission = makeSubmission(state, endType: .backExit)
            let sessionId = state.sessionId
            return .merge(
                .cancel(id: CancelID.clock),
                .cancel(id: CancelID.toast),
                .cancel(id: CancelID.submission),
                .cancel(id: CancelID.playback),
                .cancel(id: CancelID.micCapture),
                .run { send in
                    _ = try? await interviewClient.submitAnswer(sessionId, submission)
                    await send(.inner(.earlyExitSubmissionFinished))
                }
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
            state.isExitConfirmPresented = false
            // 비행 중 제출이 있으면 그 응답이 곧 종료를 판정한다 — 중복 제출하지 않는다.
            guard !state.isSubmitting else { return .none }
            state.phase = .processingAnswer
            return submitCurrentAnswer(&state, endType: .manualEnd)
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case let .previewStarted(handle):
            state.previewHandle = handle
            return .none

        case let .recordingStarted(success):
            return reduceRecordingStarted(&state, success: success)

        case .wrapUpPlaybackFinished:
            guard state.isWrappingUp else { return .none }
            state.isWrappingUp = false
            state.wrapUpSpan = state.wrapUpStartedAt.map {
                InterviewVideoWrapUpSpan(wrapUpStartSec: Double($0), wrapUpEndSec: Double(state.elapsedSeconds))
            }
            return stopRecordingAndFinish(&state)

        case let .recordingStopped(ref):
            // 마감이 끝난 지금에야 마이크를 끊는다 — 먼저 끊으면 stopCapture 가 세션 기록을 폐기한다.
            return .merge(
                .cancel(id: CancelID.micCapture),
                .send(.delegate(.finished(ref, state.wrapUpSpan)))
            )

        case .clockTicked:
            return reduceClockTick(&state)

        case .questionPlaybackFinished:
            guard state.phase == .asking else { return .none }
            state.phase = .answering
            state.questionAudioEndedAt = state.elapsedSeconds
            state.answerStartedAt = state.elapsedSeconds
            // AI 발화가 끝났으니 세션 오디오를 되살린 뒤(무음 해제) 답변 구간 m4a 기록을 연다
            // (제출 시 answerAudio() 로 회수 — 스펙 §②). 순서를 보장하려고 한 effect 에 둔다.
            return .run { _ in
                await speechClient.setSessionAudioMuted(false)
                await speechClient.startAnswerRecording()
            }

        case .questionPlaybackFailed:
            guard state.phase == .asking else { return .none }
            guard !state.hasRetriedPlayback else {
                return reduceInner(&state, .failureDetected(.network))
            }
            // 같은 questionId 재호출 = 서버가 TTS 를 처음부터 재생성한다([[api#Interview]] 스트리밍 규약).
            state.hasRetriedPlayback = true
            return playCurrentQuestion(state)

        case .exitNoticeExpired:
            guard state.toast == .exitUnlocked else { return .none }
            state.toast = nil
            return .none

        case let .answerSubmitted(result):
            state.isSubmitting = false
            if result.sessionEnded {
                return endSession(&state, result: result)
            }
            if let next = result.nextQuestion {
                state.currentQuestion = ActiveQuestion(next)
                state.hasRetriedPlayback = false
                if state.hardCapReachedWhileSubmitting {
                    // 비행 중 상한 도달 — 새 질문을 여는 대신 즉시 HARD_CAP 으로 마감한다.
                    state.phase = .processingAnswer
                    return submitCurrentAnswer(&state, endType: .hardCap)
                }
                if state.phase == .finalCountdown {
                    // 초읽기 중엔 재생을 열지 않는다 — 12:00 도달이 HARD_CAP 으로 마감한다.
                    return .none
                }
                guard state.phase == .processingAnswer else { return .none }
                state.phase = .asking
                state.questionAudioStartedAt = state.elapsedSeconds
                state.questionAudioEndedAt = nil
                state.answerStartedAt = nil
                return playCurrentQuestion(state)
            }
            // sessionEnded 도 다음 질문도 아니다 — 계약 위반 응답.
            return reduceInner(&state, .failureDetected(.network))

        case let .answerSubmissionFailed(error):
            state.isSubmitting = false
            switch error {
            case .sessionAlreadyEnded:
                // 이미 종료된 세션(409) — 리포트 대기로 넘어간다. 녹화가 있으면 그래도 정지·업로드 경로를 탄다.
                state.isExitConfirmPresented = false
                guard state.hasRecording else {
                    return .merge(sessionCleanup(), .send(.delegate(.finished(nil, nil))))
                }
                return stopRecordingAndFinish(&state)
            default:
                return reduceInner(&state, .failureDetected(.network))
            }

        case .earlyExitSubmissionFinished:
            return .send(.delegate(.aborted))

        case let .failureDetected(kind):
            state.isExitConfirmPresented = false
            return .merge(sessionCleanup(), .send(.delegate(.failed(kind))))
        }
    }

    /// 녹화 시작 종료 — 이 순간이 타임라인 0점이다(스펙 §①). 시계·세션 오디오·첫 질문 재생을 한꺼번에 연다.
    /// 시작 실패(success == false)여도 면접은 그대로 진행한다 — 영상 없는 리포트로 수렴(스펙 §⑥).
    private func reduceRecordingStarted(_ state: inout State, success: Bool) -> Effect<Action> {
        state.hasRecording = success
        state.questionAudioStartedAt = state.elapsedSeconds
        return .merge(
            .run { send in
                for await _ in clock.timer(interval: Self.clockTick) {
                    await send(.inner(.clockTicked))
                }
            }
            .cancellable(id: CancelID.clock),
            // 세션 오디오는 녹화 성공 시에만 — 합성 입력이 없으면 어차피 포기 경로(스펙 §⑥).
            // 캡처 구독과 같은 effect 로 묶어 «엔진 먼저» 순서를 보장한다(micCaptureLogging 주석 참조).
            micCaptureLogging(startsSessionAudio: success),
            playCurrentQuestion(state)
        )
    }

    /// 세션 시계 1초 진행 — 8:00 해금, 상한 10초 전 최종 카운트다운, 상한 도달 시 HARD_CAP 제출.
    private func reduceClockTick(_ state: inout State) -> Effect<Action> {
        state.elapsedSeconds += 1

        if state.isWrappingUp { return .none }   // 계측 전용 tick — 해금·상한 로직 잠금

        if state.elapsedSeconds >= Self.hardCapSeconds {
            return reachHardCap(&state)
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

    /// 12:00 상한 — 시계를 멈추고 HARD_CAP 을 제출한다(제출 완료까지 processingAnswer 로 대기 표현).
    /// 이미 제출이 비행 중이면 그 응답 수신이 마감을 잇는다(hardCapReachedWhileSubmitting).
    private func reachHardCap(_ state: inout State) -> Effect<Action> {
        state.isExitConfirmPresented = false
        state.isEarlyExitWarningPresented = false
        if state.isSubmitting {
            state.hardCapReachedWhileSubmitting = true
            return .cancel(id: CancelID.clock)
        }
        state.phase = .processingAnswer
        return .merge(
            .cancel(id: CancelID.clock),
            .cancel(id: CancelID.playback),
            submitCurrentAnswer(&state, endType: .hardCap)
        )
    }

    /// 서버가 세션 종료를 알렸다 — endType 별 delegate 로 갈라 통보한다(스펙 §5.2-3).
    private func endSession(_ state: inout State, result: AnswerResult) -> Effect<Action> {
        state.isExitConfirmPresented = false
        switch result.endType {
        case .backExit:
            return .merge(sessionCleanup(), .send(.delegate(.aborted)))
        case .sttReset:
            return .merge(sessionCleanup(), .send(.delegate(.failed(.speechRecognition))))
        case .normalEnd, .manualEnd, .hardCap, nil:
            let audioData = result.wrapUpMessage?.audioData
            guard state.hasRecording else {
                // 녹화 없음 — 마무리 멘트는 fire-and-forget 으로 걸어두고 즉시 종료(영상 없는 리포트).
                // 재생 주체는 Implementation 액터라 effect 종료·화면 교체에도 재생은 지속된다(PRD §3.7).
                let wrapUp: Effect<Action> = audioData.map { data in
                    .run { _ in _ = await speechClient.play(data) }
                } ?? .none
                return .merge(wrapUp, sessionCleanup(), .send(.delegate(.finished(nil, nil))))
            }
            guard let audioData else {
                // 멘트 오디오 없음 — 즉시 정지, wrapUp = nil 업로드 경로(스펙 §①).
                return stopRecordingAndFinish(&state)
            }
            // 마무리 멘트를 영상에 담는다 — 재생 완료 후 정지(스펙 §①). 구간은 세션 시계로 계측.
            state.isWrappingUp = true
            state.wrapUpStartedAt = state.elapsedSeconds
            return .merge(
                .cancel(id: CancelID.toast),
                // HARD_CAP 경로는 시계가 이미 취소됨 — 계측을 위해 다시 돌린다.
                .run { send in
                    for await _ in clock.timer(interval: Self.clockTick) {
                        await send(.inner(.clockTicked))
                    }
                }
                .cancellable(id: CancelID.clock, cancelInFlight: true),
                .run { send in
                    // 마무리 멘트도 서버 TTS 가 얹는 구간(wrapUpSpan 계약) — 재생 전에 무음으로 건다.
                    // 해제는 없다: 이 재생이 끝나면 곧바로 세션 오디오 마감이라 이후 기록 자체가 없다.
                    await speechClient.setSessionAudioMuted(true)
                    for await _ in await speechClient.play(audioData) { break }   // finished/failed 첫 이벤트가 곧 재생 종료
                    await send(.inner(.wrapUpPlaybackFinished))
                }
                .cancellable(id: CancelID.playback, cancelInFlight: true)
            )
        }
    }

    /// 세션 오디오 마감 → 녹화 정지+합성 → 종료 통보 — 실패는 nil ref(영상 없는 리포트, 스펙 §⑥).
    ///
    /// **마이크 취소를 여기서 빼는 이유(경합 제거)**: `.cancel(id: .micCapture)` → 스트림 종료 → `stopCapture()`
    /// → 진행 중이던 세션 기록 **폐기**다. 마감(`finishSessionAudioRecording`)과 merge 로 같이 걸면 어느 쪽이
    /// 먼저인지 미보장이라 정상 종료마다 산출물이 통째로 날아갈 수 있다. 그래서 마감이 끝난 뒤
    /// `recordingStopped` 가 마이크를 끊는다 — 그 사이 캡처가 조금 더 도는 건 무해하다(파일은 이미 닫힘).
    ///
    /// **재진입 가드(`isFinishing`)**: 정지+합성은 수 초 걸리고 그동안 액터의 recording 은 이미 비어 있어,
    /// 두 번째 호출은 즉시 throw 해 `finished(nil, nil)` 을 진짜 결과보다 **먼저** 내보낸다 —
    /// 코디네이터의 first-wins 가 진짜 ref 를 버리고 영상이 조용히 사라진다.
    private func stopRecordingAndFinish(_ state: inout State) -> Effect<Action> {
        guard !state.isFinishing else { return .none }
        state.isFinishing = true
        return .merge(
            sessionCleanup(includingMicCapture: false),
            .run { send in
                let audio = await speechClient.finishSessionAudioRecording()
                let ref: RecordingRef?
                do {
                    ref = try await recordingClient.stopRecording(audio?.fileURL, audio?.startedAtHostSeconds)
                } catch {
                    Self.recordingLogger.error("녹화 정지·합성 실패: \(String(describing: error))")
                    ref = nil
                }
                await send(.inner(.recordingStopped(ref)))
            }
        )
    }

    /// 세션 effect 일괄 취소 — 시계·토스트·제출·재생·마이크. 화면 전환(보고서·닫기)은 상위 몫.
    /// `includingMicCapture: false` 는 정지+합성 경로 전용 — 마이크 취소가 세션 오디오를 폐기하기 때문
    /// (`stopRecordingAndFinish` 주석). 그 경로에선 마감 후 `recordingStopped` 가 대신 끊는다.
    private func sessionCleanup(includingMicCapture: Bool = true) -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.clock),
            .cancel(id: CancelID.toast),
            .cancel(id: CancelID.submission),
            includingMicCapture ? .cancel(id: CancelID.micCapture) : .none,
            .cancel(id: CancelID.playback)
        )
    }

    /// 진행 중 질문 재생 — 요약 질문(턴 0)은 동봉 mp3(`play`), 이후 질문은 chunked 스트림(`playStream`).
    /// 요약 질문에 오디오가 없으면(계약상 없을 일) 스트림으로 폴백한다.
    private func playCurrentQuestion(_ state: State) -> Effect<Action> {
        let question = state.currentQuestion
        let summaryAudio = question.questionId == state.summaryQuestion.questionId
            ? state.summaryQuestion.audioData
            : nil
        let sessionId = state.sessionId
        return .run { send in
            // 질문 TTS 는 서버가 영상에 다시 얹는 구간 — 스피커 에코가 이중 음성이 되지 않게 먼저 무음으로 건다.
            // 요약·스트림·재시도가 전부 이 단일 진입점을 지나므로 여기 한 곳이면 충분하다(해제는 answering 진입).
            await speechClient.setSessionAudioMuted(true)
            let events: AsyncStream<PlaybackEvent>
            if let summaryAudio {
                events = await speechClient.play(summaryAudio)
            } else {
                do {
                    let stream = try await interviewClient.questionAudioStream(sessionId, question.questionId)
                    events = await speechClient.playStream(stream.url, stream.headers)
                } catch is CancellationError {
                    return
                } catch {
                    Self.playbackLogger.error("질문 스트림 요청 실패: \(String(describing: error))")
                    return await send(.inner(.questionPlaybackFailed))
                }
            }
            for await event in events {
                switch event {
                case .finished:
                    return await send(.inner(.questionPlaybackFinished))
                case let .failed(reason):
                    Self.playbackLogger.error("질문 재생 실패: \(reason)")
                    return await send(.inner(.questionPlaybackFailed))
                }
            }
        }
        .cancellable(id: CancelID.playback, cancelInFlight: true)
    }

    /// 답변 제출 — 시간 마킹을 실은 submission 에 답변 오디오를 채워 503 백오프로 보낸다.
    /// 제출형 종료(마치기·상한)도 이 경로다 — endType 만 다르다.
    private func submitCurrentAnswer(_ state: inout State, endType: AnswerEndType?) -> Effect<Action> {
        state.isSubmitting = true
        let submission = makeSubmission(state, endType: endType)
        let sessionId = state.sessionId
        return .run { send in
            do {
                await send(.inner(.answerSubmitted(try await submitWithRetry(sessionId, submission))))
            } catch is CancellationError {
            } catch let error as InterviewError {
                await send(.inner(.answerSubmissionFailed(error)))
            } catch {
                await send(.inner(.answerSubmissionFailed(.unexpected)))
            }
        }
        .cancellable(id: CancelID.submission, cancelInFlight: true)
    }

    /// 시간 마킹(세션 시계 스냅샷 — 실녹화 전 근사값)을 Double 계약으로 변환한다.
    private func makeSubmission(_ state: State, endType: AnswerEndType?) -> AnswerSubmission {
        AnswerSubmission(
            questionId: state.currentQuestion.questionId,
            questionAudioStartAt: state.questionAudioStartedAt.map(Double.init),
            questionAudioEndAt: state.questionAudioEndedAt.map(Double.init),
            answerStartAt: state.answerStartedAt.map(Double.init),
            answerEndAt: state.answerStartedAt.map { _ in Double(state.elapsedSeconds) },
            answerDuration: state.answerStartedAt.map { Double(state.elapsedSeconds - $0) },
            endType: endType,
            isWrapUp: state.elapsedSeconds >= Self.wrapUpThresholdSeconds
        )
    }

    /// 제출 + 503 백오프 — `aiTemporarilyUnavailable`(서버에 아무것도 저장 안 됨)만 같은 요청을 재시도한다.
    private func submitWithRetry(_ sessionId: Int, _ submission: AnswerSubmission) async throws -> AnswerResult {
        var submission = submission
        submission.audio = await speechClient.answerAudio()
        for delay in Self.submissionRetryDelays {
            do {
                return try await interviewClient.submitAnswer(sessionId, submission)
            } catch let error as InterviewError where error == .aiTemporarilyUnavailable {
                try await clock.sleep(for: delay)
            }
        }
        return try await interviewClient.submitAnswer(sessionId, submission)
    }

    /// 마이크 캡처 검증 로그 — 세션 전구간 구독(State 무변화). STT 도입 시 이벤트를 inner 로 승격한다.
    /// 정지는 코디네이터 stopCaptureDevices + 취소 양쪽.
    ///
    /// `startsSessionAudio` 를 별도 effect 로 떼지 않는 이유: `startSessionAudioRecording` 은 캡처 엔진이
    /// 세팅하는 tap 포맷을 전제로 하고, 없으면 **조용히 무시**된다(SpeechClientLive `guard let tapFormat`).
    /// merge 로 두면 두 Task 의 순서가 미보장이라 세션 오디오가 먼저 도착하는 순간 항상 무기록이 되고,
    /// finish 가 nil → stopRecording throw → 모든 세션이 영상 없는 리포트로 수렴한다.
    /// `startCapture()` 반환 시점엔 엔진 시작이 끝나 있으므로 같은 effect 안에서 이어 부른다.
    private func micCaptureLogging(startsSessionAudio: Bool) -> Effect<Action> {
        .run { _ in
            let events = await speechClient.startCapture()
            if startsSessionAudio {
                await speechClient.startSessionAudioRecording()
            }
            for await event in events {
                switch event {
                case let .level(decibels):
                    Self.micLogger.info("입력 레벨 \(decibels, format: .fixed(precision: 1), align: .right(columns: 6)) dBFS")
                case .speechStarted:
                    Self.micLogger.notice("음성 감지 시작")
                case .speechEnded:
                    Self.micLogger.notice("음성 감지 종료")
                case let .captureFailed(reason):
                    Self.micLogger.error("마이크 캡처 시작 실패: \(reason)")
                }
            }
        }
        .cancellable(id: CancelID.micCapture)
    }
}
