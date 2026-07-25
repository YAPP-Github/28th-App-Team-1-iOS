//
//  ReportFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import Foundation

// @lat: [[report#코디네이터]]
/// AI 면접 리포트 코디네이터. 리포트 메인을 루트로 두고, 이후 화면은 `path`(StackState)로 push 한다.
/// 각 화면의 delegate 만 매칭해 전환한다 — 화면 간 직접 의존 없음, 조립은 여기서만 (D5).
/// ⚠️ 전환 순서(메인 → 영상 → 피드백 → 최종)는 디자인 확정 전 임시 선형 플로우 — Figma 연결 시 조정한다.
@Reducer
public struct ReportFeature {
    @Reducer
    public enum Path {
        case videoPlayer(ReportVideoPlayerFeature)   // 2. 영상 플레이어
        case peerFeedback(ReportPeerFeedbackFeature)         // 3. 피드백
        case final(ReportFinalFeature)               // 4. 최종
    }

    // @Reducer enum 이 생성하는 Path.State 는 Equatable 을 자동 채택하지 않는다 —
    // StackState<Path.State> 를 담는 코디네이터 State 의 Equatable 합성을 위해 명시한다.

    @ObservableState
    public struct State: Equatable {
        /// 루트 화면(리포트 메인).
        public var main: ReportMainFeature.State
        /// 이후 화면 네비게이션 스택.
        public var path = StackState<Path.State>()

        public init(main: ReportMainFeature.State = .init()) {
            self.main = main
        }
    }

    public enum Action {
        case main(ReportMainFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 리포트 이탈(X) — dismiss 는 부모(AppFeature)가 처리한다.
            case closeRequested
            /// 리포트 플로우 완료 — 이후 전환은 부모가 처리한다.
            case finished
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.main, action: \.main) {
            ReportMainFeature()
        }

        Reduce { state, action in
            switch action {
            // 메인 완료 → 영상 플레이어 push (임시 선형 플로우).
            case .main(.delegate(.continueRequested)):
                state.path.append(.videoPlayer(.init()))
                return .none

            case .main(.delegate(.closeRequested)):
                return .send(.delegate(.closeRequested))

            case .main:
                return .none

            // 영상 플레이어 완료 → 피드백 push.
            case .path(.element(id: _, action: .videoPlayer(.delegate(.continueRequested)))):
                state.path.append(.peerFeedback(.init()))
                return .none

            // 피드백 완료 → 최종 push.
            case .path(.element(id: _, action: .peerFeedback(.delegate(.continueRequested)))):
                state.path.append(.final(.init()))
                return .none

            // 최종 완료 → 플로우 종료 통보.
            case .path(.element(id: _, action: .final(.delegate(.continueRequested)))):
                return .send(.delegate(.finished))

            // 뒤로 — 스택 pop.
            case .path(.element(id: _, action: .videoPlayer(.delegate(.backRequested)))),
                 .path(.element(id: _, action: .peerFeedback(.delegate(.backRequested)))),
                 .path(.element(id: _, action: .final(.delegate(.backRequested)))):
                _ = state.path.popLast()
                return .none

            // 이탈(X) — 어느 화면에서든 부모 통보.
            case .path(.element(id: _, action: .videoPlayer(.delegate(.closeRequested)))),
                 .path(.element(id: _, action: .peerFeedback(.delegate(.closeRequested)))),
                 .path(.element(id: _, action: .final(.delegate(.closeRequested)))):
                return .send(.delegate(.closeRequested))

            case .path:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension ReportFeature.Path.State: Equatable {}
