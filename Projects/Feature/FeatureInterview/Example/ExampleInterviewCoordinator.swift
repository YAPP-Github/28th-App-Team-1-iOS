//
//  ExampleInterviewCoordinator.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/08/07.
//

import ComposableArchitecture
import FeatureInterviewImplementation

/// 하네스 전용 부모 — 실앱 `AppFeature` 가 면접 종료 두 신호로 하는 일(cover 를 닫고 홈 복귀)을 최소로 흉내 낸다.
///
/// 없으면 `InterviewFeature` 를 맨몸으로 띄우게 되는데, 정상 종료엔 갈아탈 화면이 없어 `screen` 이 `.session` 에
/// 머문다(`InterviewFeature.State.isClosing` 주석). 신호는 정상적으로 올라가는데 받을 사람이 없어 화면만 안 바뀌는
/// 상태라, 실기기에서 «종료했는데 안 나가진다» 로 보인다 — 2026-08-07 에 이걸 제품 버그로 오진했다.
@Reducer
struct ExampleInterviewCoordinator {
    @ObservableState
    struct State: Equatable {
        var interview: InterviewFeature.State
        /// 종료 결과 — 실앱은 여기서 홈으로 돌아가고, 하네스는 확인 화면을 띄운다.
        var outcome: Outcome?

        enum Outcome: Equatable {
            /// 정상 종료 — 산출물이 업로드 큐로 넘어갔다.
            case finished
            /// 흐름 이탈(중도 이탈·실패 화면 닫기) — 녹화는 폐기됐다.
            case closed
        }

        init(sessionId: Int) {
            self.interview = InterviewFeature.State(sessionId: sessionId)
        }
    }

    enum Action {
        case interview(InterviewFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.interview, action: \.interview) {
            InterviewFeature()
        }
        Reduce { state, action in
            switch action {
            case .interview(.delegate(.finished)):
                state.outcome = .finished
                return .none
            case .interview(.delegate(.closed)):
                state.outcome = .closed
                return .none
            case .interview:
                return .none
            }
        }
    }
}
