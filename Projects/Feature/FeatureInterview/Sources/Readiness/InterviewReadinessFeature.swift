//
//  InterviewReadinessFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture

// @lat: [[interview#준비]]
/// Part 2 진입 첫 화면 — 카메라 확인 + 면접 안내 (Figma «[2] Interview_Readiness» 2479:7569 ·
/// «…_Done» 2514:12754 · «…_Guide1» 2514:12799 · «…_Guide2» 2529:458).
/// 화면 push 없이 단일 카메라 화면 위에서 phase 로만 전환한다:
/// aligning(얼굴 맞춤) → ready(티커 강조) → guide1(질문은 소리로만) → guide2(총 10분 · 시작 버튼 활성).
/// 시작 버튼 탭은 delegate(.startRequested) 로만 올린다 — 세션 화면 전환은 코디네이터 몫.
@Reducer
public struct InterviewReadinessFeature {
    /// phase 자동 진행 유지 시간 — 얼굴 인식·카메라 준비 신호가 없어 시간 연출로 채운다 (tentative).
    /// TODO: PermissionClient(카메라·마이크 사용 시점 요청, PRD §8)·RecordingClient(프리뷰) 도입 시
    /// aligning→ready 를 실제 카메라 준비 신호로 교체.
    static let aligningHold: Duration = .seconds(3)
    static let readyHold: Duration = .seconds(2)
    static let guide1Hold: Duration = .seconds(3)

    @ObservableState
    public struct State: Equatable {
        /// 화면 하위 상태 — 순서대로만 진행한다 (역방향 없음).
        public enum Phase: Equatable, Sendable {
            /// 얼굴 맞춤 안내 + 하단 티커(dim)
            case aligning
            /// 준비 완료 — 티커 중앙 문구 강조 (Figma Done)
            case ready
            /// 안내 1: 질문은 소리로만 — 시작 버튼 비활성
            case guide1
            /// 안내 2: 총 10분 — 시작 버튼 활성
            case guide2
        }

        public var phase: Phase = .aligning
        /// onAppear 재진입 가드 — phase 타이머 effect 중복 실행 방지.
        public var hasStarted = false

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedStart
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// phase 유지 시간 경과 — 다음 phase 로 진행할 시점.
            case phaseHoldFinished
        }

        /// 부모(코디네이터) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 면접 시작하기 탭 — 세션 화면 전환은 코디네이터가 처리.
            case startRequested
        }
    }

    private enum CancelID { case phaseTimer }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.hasStarted else { return .none }
                state.hasStarted = true
                return scheduleAdvance(after: Self.aligningHold)

            case .view(.userTappedStart):
                guard state.phase == .guide2 else { return .none }
                return .send(.delegate(.startRequested))

            case .inner(.phaseHoldFinished):
                return advancePhase(&state)

            case .delegate:
                return .none
            }
        }
    }

    /// aligning → ready → guide1 → guide2 한 칸 진행. guide2 는 종점 — 사용자 탭만 기다린다.
    private func advancePhase(_ state: inout State) -> Effect<Action> {
        switch state.phase {
        case .aligning:
            state.phase = .ready
            return scheduleAdvance(after: Self.readyHold)
        case .ready:
            state.phase = .guide1
            return scheduleAdvance(after: Self.guide1Hold)
        case .guide1:
            state.phase = .guide2
            return .none
        case .guide2:
            return .none
        }
    }

    private func scheduleAdvance(after duration: Duration) -> Effect<Action> {
        .run { send in
            try await clock.sleep(for: duration)
            await send(.inner(.phaseHoldFinished))
        }
        .cancellable(id: CancelID.phaseTimer, cancelInFlight: true)
    }
}
