//
//  GuestVideoPlaybackFeature.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/13.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import Foundation

// @lat: [[feedback#G4 게스트 평가]]
/// 게스트 영상 재생 — 평가 화면(GuestFeedbackFeature)의 자식.
///
/// **동작은 리포트 플레이어(`ReportVideoPlayerFeature`)와 같게 맞춘다** (사용자 결정 2026-08-13):
/// 영상을 탭하면 딤 + 재생 컨트롤이 뜨고 3초 뒤 사라지며, 좌우 화살표·진행바 칸은 «질문 턴» 단위로 움직인다.
/// 리포트 코드를 가져다 쓰지 못하는 건 Feature→Feature 의존이 금지라서다 — 대신 화면에 보이는 부분
/// (`VideoControl`·`VideoOverlay`)은 이미 DesignSystem 컴포넌트라 양쪽이 같은 물건을 쓴다.
/// 다른 점은 게스트엔 대본·하이라이트 시트가 없고, 칸의 출처가 서버 대본이 아니라 `questionBoundaries` 라는 것뿐.
///
/// **AVPlayer 는 State 에 두지 않는다** — 뷰 로컬 `@State` 가 소유하고(리포트와 같은 이유),
/// 리듀서는 재생 여부·시각만 갖는다. 뷰로 내리는 이동 명령은 `seekToken`(단조 증가) + `seekTarget` 쌍이다.
@Reducer
public struct GuestVideoPlaybackFeature {
    /// 컨트롤 자동 숨김까지 기다리는 시간. 손대지 않으면 영상만 남는다.
    static let controlsHideDelay: Duration = .seconds(3)
    /// 이동이 «닿았다» 고 보는 오차(초) — AVPlayer 보고 간격(0.2초)보다 넉넉하게.
    static let seekSettleTolerance: TimeInterval = 0.3
    /// 재생 실패 문구 — 만료(gate=EXPIRED)는 진입에서 걸러지므로 여기 오는 건 전송·디코딩 실패다.
    static let playbackFailureMessage = "영상을 재생할 수 없어요.\n잠시 후 다시 시도해 주세요."

    @ObservableState
    public struct State: Equatable {
        /// 진입 응답이 오기 전엔 nil — 영상 파이프라인 전 entry 도 nil 이다.
        public var videoURL: URL?
        /// 진행바 칸·좌우 화살표의 눈금. 서버가 안 주면 영상 전체가 한 칸이다.
        public var boundaries: [QuestionBoundary] = []
        public var isPlaying = false
        /// AVPlayer 가 알려주는 현재 재생 시각(초).
        public var currentTime: TimeInterval = 0
        /// AVPlayer 가 알려주는 전체 길이(초). 모르면 0.
        public var duration: TimeInterval = 0
        /// 컨트롤(딤·재생 버튼) 표시 여부 — 무입력 3초 후 숨는다.
        /// **진행바는 여기 걸리지 않는다** — 붙박이다(리포트 하단 바와 같은 규약).
        public var areControlsVisible = true
        /// 뷰가 asset 을 열어본 결과가 도착했는가 — 성공·실패 어느 쪽이든 선다.
        /// 한 번 서면 내려가지 않는다(재시도 결과가 와도 «준비를 시도해 봤다» 는 사실은 그대로다).
        public var isPrepared = false
        /// 재생 실패 — 표시할 문구를 동봉한다.
        public var playbackFailureMessage: String?
        /// 뷰가 실행할 이동 목표(초).
        public var seekTarget: TimeInterval = 0
        /// 이동 명령 일련번호. 같은 시각으로 두 번 이동해도 뷰가 알아채게 한다.
        public var seekToken = 0
        /// 이동 중 — 목표에 닿기 전 보고되는 이전 위치를 버리기 위한 표식.
        public var isSeeking = false
        /// 플레이어 재생성 명령 일련번호 — 실패한 AVPlayer 는 `play()` 로 되살아나지 않아 통째로 새로 만든다.
        public var reloadToken = 0

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        @CasePathable
        public enum View: Equatable, Sendable {
            /// 뷰가 asset 을 열어본 결과 — 재생 가능 여부를 동봉한다. 실패·URL 없음도 반드시 온다.
            case videoPrepareFinished(isPlayable: Bool)
            /// 영상 아무 곳 — 컨트롤 표시 토글.
            case userTappedSurface
            case userTappedPlayPause
            /// 진행바 칸 — 그 질문 시작으로 이동. **구간 이동은 이 경로 하나뿐이다** —
            /// 배속·±10초 건너뛰기는 지인 피드백에 두지 않기로 했다(사용자 결정 2026-08-13).
            case userTappedChunk(index: Int)
            /// 재생 실패 안내의 «다시 시도» — 플레이어를 새로 만들어 보던 시각부터 다시 건다.
            case userTappedPlaybackRetry
        }

        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// AVPlayer 주기 관찰 결과.
            case timeUpdated(TimeInterval)
            /// 전체 길이 확정.
            case durationLoaded(TimeInterval)
            /// 끝까지 재생됨 — 컨트롤을 다시 띄운다.
            case playbackFinished
            /// AVPlayer 재생 실패 — 뷰가 주기 관찰에서 올린다.
            case playbackFailed(message: String)
            /// 자동 숨김 타이머 만료.
            case controlsHideElapsed
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 준비 종결(성공·실패 무관) — 부모가 시작 연출을 걷는 조건 하나로 쓴다.
            case prepareFinished
        }
    }

    private enum CancelID { case controlsHide }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(let action):
                return reduceView(&state, action)
            case .inner(let action):
                return reduceInner(&state, action)
            case .delegate:
                return .none
            }
        }
    }

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .videoPrepareFinished(let isPlayable):
            // **첫 보고만 받고 끝내지 않는다** — 재시도(`reloadToken`)도 준비를 다시 태우고 그 결과를 여기로 올린다.
            // 첫 보고만 반영하면 «재시도 → 또 실패» 가 조용히 버려져, 실패 안내(=유일한 재시도 버튼)가
            // 사라진 채 재생도 안 되는 막다른 화면이 남는다.
            state.isPrepared = true
            if isPlayable {
                state.playbackFailureMessage = nil
            } else if state.videoURL != nil {
                // 열리지 않은 영상은 재생 실패로 표시한다 — URL 자체가 없는 경우(영상 파이프라인 전)는
                // 실패가 아니라 «아직 없음» 이라 placeholder 로 두고 문구를 걸지 않는다.
                state.playbackFailureMessage = Self.playbackFailureMessage
                // 재시도가 걸어 둔 «재생 중» 을 되돌린다 — 재생 못 하는 화면이 재생 중이라고 말하면 안 된다.
                // 실패 안내는 컨트롤 표시와 무관하게 뜨므로(딤·재생 버튼만 자동 숨김 대상) 숨김 타이머만 끈다.
                state.isPlaying = false
                return .merge(
                    .cancel(id: CancelID.controlsHide),
                    .send(.delegate(.prepareFinished))
                )
            }
            // 재시도發 보고까지 부모에게 알리지만, 시작 연출은 이미 걷혀 있어 부모가 무시한다(가드).
            return .send(.delegate(.prepareFinished))

        case .userTappedSurface:
            state.areControlsVisible.toggle()
            return state.areControlsVisible ? startControlsHideTimer() : .cancel(id: CancelID.controlsHide)

        case .userTappedPlayPause:
            // 끝까지 본 뒤 누르면 처음부터 — AVPlayer 는 끝에 멈춘 채로 play() 해도 움직이지 않는다.
            if !state.isPlaying, state.hasReachedEnd {
                return seek(&state, to: 0, resuming: true)
            }
            state.isPlaying.toggle()
            state.areControlsVisible = true
            // 멈춰 둔 채로는 컨트롤을 숨기지 않는다 — 다시 재생할 방법이 사라진다.
            return state.isPlaying ? startControlsHideTimer() : .cancel(id: CancelID.controlsHide)

        case .userTappedChunk(let index):
            // 질문 경계가 없을 때의 대체 칸(영상 전체 한 덩어리)은 이동 대상이 아니다 —
            // 바 아무 데나 눌렀다고 처음으로 되감기면 사고다(리포트 플레이어도 같은 규약).
            guard state.hasQuestionSections,
                  let chunk = state.progressChunks.first(where: { $0.id == index })
            else { return .none }
            return seek(&state, to: chunk.start)

        case .userTappedPlaybackRetry:
            state.playbackFailureMessage = nil
            state.reloadToken += 1
            state.isPlaying = true
            state.areControlsVisible = true
            return startControlsHideTimer()
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case .timeUpdated(let time):
            // 이동 직후 한두 번은 AVPlayer 가 아직 이전 위치를 보고한다 —
            // 목표에 닿기 전 값을 그대로 쓰면 진행바가 눌렀던 자리에서 되돌아간다.
            if state.isSeeking {
                guard abs(time - state.seekTarget) < Self.seekSettleTolerance else { return .none }
                state.isSeeking = false
            }
            state.currentTime = time
            return .none

        case .durationLoaded(let duration):
            state.duration = duration
            return .none

        case .playbackFinished:
            state.isPlaying = false
            state.areControlsVisible = true
            return .cancel(id: CancelID.controlsHide)

        case .playbackFailed(let message):
            state.playbackFailureMessage = message
            state.isPlaying = false
            return .cancel(id: CancelID.controlsHide)

        case .controlsHideElapsed:
            state.areControlsVisible = false
            return .none
        }
    }

    /// 이동 명령. 목표 시각을 영상 범위로 자르고 토큰을 올려 뷰가 seek 하게 한다.
    private func seek(
        _ state: inout State,
        to time: TimeInterval,
        resuming: Bool = false
    ) -> Effect<Action> {
        // duration 을 아직 모르면(0) 상한을 걸지 않는다 — 0 으로 잘라 앞으로 못 가는 걸 막는다.
        let upperBound = state.duration > 0 ? state.duration : .greatestFiniteMagnitude
        let target = min(max(0, time), upperBound)
        state.seekTarget = target
        state.seekToken += 1
        state.currentTime = target
        state.isSeeking = true
        state.areControlsVisible = true
        if resuming { state.isPlaying = true }
        return state.isPlaying ? startControlsHideTimer() : .cancel(id: CancelID.controlsHide)
    }

    private func startControlsHideTimer() -> Effect<Action> {
        .run { send in
            try await clock.sleep(for: Self.controlsHideDelay)
            await send(.inner(.controlsHideElapsed))
        }
        .cancellable(id: CancelID.controlsHide, cancelInFlight: true)
    }
}
