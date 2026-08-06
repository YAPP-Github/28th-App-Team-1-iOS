//
//  InterviewReportPendingFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/27.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import OSLog

// @lat: [[interview#리포트 대기]]
/// 면접 종료 후 리포트 대기 화면 (Interview_ReportPending, PRD §3.8) — «리포트를 만들고 있어요» + 홈으로.
/// 세션 화면이 넘긴 녹화 산출물이 있으면 **조용히** 업로드한다(새 UI 없음, 스펙 §④) —
/// 1차 실패 시 즉시 1회 재시도(발급부터 재시작), 2차 실패 시 조용한 포기. 종착은 항상 파일 삭제.
/// 금지 문구(§3.8): «나가도 돼요» · «앱을 닫아도 돼요» · «완료되면 알려드려요»(푸시 없음 — 못 지킬 약속).
@Reducer
public struct InterviewReportPendingFeature {
    @ObservableState
    public struct State: Equatable {
        /// 세션 화면이 넘긴 녹화 산출물 — nil 이면 업로드 없이 안내만(영상 없는 리포트).
        public let recording: RecordingRef?
        /// 마무리 멘트 재생 구간(녹화 타임라인 초) — nil 이면 complete 바디 생략 경로.
        public let wrapUp: InterviewVideoWrapUpSpan?
        /// onAppear 재진입 가드 — 업로드 effect 중복 실행 방지.
        public var hasStarted = false

        public init(recording: RecordingRef? = nil, wrapUp: InterviewVideoWrapUpSpan? = nil) {
            self.recording = recording
            self.wrapUp = wrapUp
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedGoHome
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// 업로드 종료(성공·포기 공통) — 파일은 이미 삭제됐다. 사용자 통보 없음(스펙 §④).
            case uploadFinished
        }

        /// 부모(코디네이터) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 홈으로 — 면접 흐름 종료(정상). dismiss 는 AppFeature 몫.
            case goHomeRequested
        }
    }

    private enum CancelID { case upload }

    /// 조용한 실패 정책(스펙 §④) — 사용자 통보 없이 로그만 남긴다.
    static let uploadLogger = Logger(subsystem: "FeatureInterview", category: "VideoUpload")

    @Dependency(\.interviewClient) var interviewClient
    @Dependency(\.recordingClient) var recordingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard let recording = state.recording, !state.hasStarted else { return .none }
                state.hasStarted = true
                let wrapUp = state.wrapUp
                return .run { send in
                    do {
                        try await interviewClient.uploadInterviewVideo(recording.sessionId, recording.fileURL, wrapUp)
                    } catch is CancellationError {
                        return
                    } catch {
                        // 1차 실패 → 발급부터 즉시 1회 재시도 — 새 URL 로 만료 해소, PUT 덮어쓰기·complete 멱등(스펙 §④).
                        Self.uploadLogger.error("영상 업로드 1차 실패: \(String(describing: error))")
                        do {
                            try await interviewClient.uploadInterviewVideo(recording.sessionId, recording.fileURL, wrapUp)
                        } catch is CancellationError {
                            return
                        } catch {
                            // 2차 실패 → 조용한 포기 — 리포트는 영상 없이 유효(서버 1급 폴백, 스펙 §⑥).
                            Self.uploadLogger.error("영상 업로드 포기: \(String(describing: error))")
                        }
                    }
                    await recordingClient.discardRecording()   // 성공·포기 공통 — tmp 파일 삭제
                    await send(.inner(.uploadFinished))
                }
                .cancellable(id: CancelID.upload)

            case .view(.userTappedGoHome):
                // 업로드 미완이면 취소 + 파일 삭제 후 이탈 — 잡아두지 않는다(스펙 §⑤).
                return .merge(
                    .cancel(id: CancelID.upload),
                    .run { _ in await recordingClient.discardRecording() },
                    .send(.delegate(.goHomeRequested))
                )

            case .inner(.uploadFinished), .delegate:
                return .none
            }
        }
    }
}
