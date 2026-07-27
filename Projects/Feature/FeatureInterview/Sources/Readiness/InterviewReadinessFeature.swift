//
//  InterviewReadinessFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import DomainPermissionInterface

// @lat: [[interview#준비]]
/// Part 2 진입 첫 화면 — 카메라 확인 + 면접 안내 (Figma «[2] Interview_Readiness» 2479:7569 ·
/// «…_Done» 2514:12754 · «…_Guide1» 2514:12799 · «…_Guide2» 2529:458).
/// 진입 시 카메라·마이크 권한을 사용 시점 요청(PRD §8)만 하고 — 거부돼 있어도 가이드는 조용히 진행 —
/// 게이트는 «면접 시작하기» 탭: 미허용이면 설정 유도 alert(닫기 = 화면 유지, 재시도는 재탭).
/// 화면 push 없이 단일 카메라 화면 위에서 phase 로만 전환한다:
/// aligning(얼굴 맞춤) → ready(티커 강조) → guide1(질문은 소리로만) → guide2(총 10분 · 시작 버튼 활성).
/// 시작 버튼 탭은 delegate(.startRequested) 로만 올린다 — 세션 화면 전환은 코디네이터 몫.
@Reducer
public struct InterviewReadinessFeature {
    /// phase 자동 진행 유지 시간 — 얼굴 인식·카메라 준비 신호가 없어 시간 연출로 채운다 (tentative).
    /// TODO: RecordingClient(프리뷰) 도입 시 aligning→ready 를 실제 카메라 준비 신호로 교체.
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
        /// onAppear 재진입 가드 — phase 타이머·권한 요청 effect 중복 실행 방지.
        public var hasStarted = false
        /// 시작하기 탭 시 권한 미허용이면 띄우는 설정 유도 alert.
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case alert(PresentationAction<Alert>)
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

        /// 권한 미허용 alert 버튼.
        @CasePathable
        public enum Alert: Equatable, Sendable {
            /// 설정으로 이동 — 앱 권한 설정 화면을 연다.
            case openSettings
            /// 닫기 — alert 만 닫고 화면 유지. 재시도는 시작하기 재탭.
            case close
        }

        /// 부모(코디네이터) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 면접 시작하기 탭(권한 허용 확인 후) — 세션 화면 전환은 코디네이터가 처리.
            case startRequested
        }
    }

    private enum CancelID { case phaseTimer }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.permissionClient) var permissionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.hasStarted else { return .none }
                state.hasStarted = true
                return .merge(
                    requestPermissionsOnEntry(),
                    scheduleAdvance(after: Self.aligningHold)
                )

            case .view(.userTappedStart):
                guard state.phase == .guide2 else { return .none }
                // 진입 다이얼로그는 모달이라 여기 도달하면 권한은 전부 결정된 상태 — 동기 status 확인으로 충분.
                let allGranted = [MediaPermission.camera, .microphone]
                    .allSatisfy { permissionClient.status($0) == .granted }
                guard allGranted else {
                    state.alert = Self.permissionDeniedAlert()
                    return .none
                }
                return .send(.delegate(.startRequested))

            case .inner(.phaseHoldFinished):
                return advancePhase(&state)

            case .alert(.presented(.openSettings)):
                return .run { _ in await permissionClient.openSettings() }

            case .alert:
                // 닫기 포함 — alert 만 닫고 화면 유지(ifLet 이 dismiss 처리). 재시도는 시작하기 재탭.
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    /// 권한 미허용 시 설정 유도 alert. ⚠️ 문구는 임시 — PRD/PM 확정본 나오면 여기만 교체.
    static func permissionDeniedAlert() -> AlertState<Action.Alert> {
        AlertState {
            TextState("카메라·마이크 권한이 필요해요")
        } actions: {
            ButtonState(action: .openSettings) {
                TextState("설정으로 이동")
            }
            ButtonState(role: .cancel, action: .close) {
                TextState("닫기")
            }
        } message: {
            TextState("면접을 진행하려면 카메라와 마이크 권한이 모두 필요해요.\n설정에서 권한을 허용해주세요.")
        }
    }

    /// 진입 시 사용 시점 요청(PRD §8) — notDetermined 만 시스템 다이얼로그가 뜬다.
    /// 거부돼 있어도 여기선 알리지 않는다(게이트는 시작하기 탭). 하나가 거부여도 나머지도
    /// 끝까지 요청한다 — 요청해야 설정 앱에 토글이 노출된다.
    private func requestPermissionsOnEntry() -> Effect<Action> {
        .run { _ in
            for permission in [MediaPermission.camera, .microphone]
            where permissionClient.status(permission) == .notDetermined {
                _ = await permissionClient.request(permission)
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
