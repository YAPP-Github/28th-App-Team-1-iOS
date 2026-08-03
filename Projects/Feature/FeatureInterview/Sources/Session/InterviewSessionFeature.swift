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
            case finished
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
        switch action {
        case .onAppear:
            guard !state.hasStarted else { return .none }
            state.hasStarted = true
            state.questionAudioStartedAt = state.elapsedSeconds
            return .merge(
                .run { send in
                    await send(.inner(.previewStarted(recordingClient.startPreview())))
                },
                .run { send in
                    for await _ in clock.timer(interval: Self.clockTick) {
                        await send(.inner(.clockTicked))
                    }
                }
                .cancellable(id: CancelID.clock),
                micCaptureLogging(),
                playCurrentQuestion(state)
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

        case .clockTicked:
            return reduceClockTick(&state)

        case .questionPlaybackFinished:
            guard state.phase == .asking else { return .none }
            state.phase = .answering
            state.questionAudioEndedAt = state.elapsedSeconds
            state.answerStartedAt = state.elapsedSeconds
            return .none

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
                // 이미 종료된 세션(409) — 리포트 대기로 넘어간다.
                state.isExitConfirmPresented = false
                return .merge(sessionCleanup(), .send(.delegate(.finished)))
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

    /// 세션 시계 1초 진행 — 8:00 해금, 상한 10초 전 최종 카운트다운, 상한 도달 시 HARD_CAP 제출.
    private func reduceClockTick(_ state: inout State) -> Effect<Action> {
        state.elapsedSeconds += 1

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
            // 마무리 멘트는 fire-and-forget — 리포트 대기 전환을 멈춰 세우지 않는다(PRD §3.7).
            // 재생 주체는 Implementation 액터라 effect 종료·화면 교체에도 재생은 지속된다.
            let wrapUp: Effect<Action> = (result.wrapUpMessage?.audioData).map { data in
                .run { _ in _ = await speechClient.play(data) }
            } ?? .none
            return .merge(wrapUp, sessionCleanup(), .send(.delegate(.finished)))
        }
    }

    /// 세션 effect 일괄 취소 — 시계·토스트·제출·재생·마이크. 화면 전환(보고서·닫기)은 상위 몫.
    private func sessionCleanup() -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.clock),
            .cancel(id: CancelID.toast),
            .cancel(id: CancelID.submission),
            .cancel(id: CancelID.micCapture),
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
    private func micCaptureLogging() -> Effect<Action> {
        .run { _ in
            for await event in await speechClient.startCapture() {
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
