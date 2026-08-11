//
//  InterviewFailureFeature.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture

/// 면접 중단 실패 종류 — 세션이 감지해 delegate 로 올리고, 코디네이터가 실패 화면으로 전환한다.
public enum InterviewFailureKind: Equatable, Sendable {
    /// STT 인식 불가 (P3 — 30% 실패 임계, work doc §6-e)
    case speechRecognition
    /// 네트워크 단절
    case network
    /// 질문 준비(preload) 최종 실패 — 서버 FAILED (PRD §3.2). 재시도 없음·이용권 미차감(서버 자동 환불).
    case questionPrep
}

// @lat: [[interview#실패]]
/// 면접 실패 안내 화면 — Figma «[2] Interview_SttFailure»(2550:7504) ·
/// «[2] Interview_NetworkFailure»(2638:17018). 두 프레임은 배지 글리프·문구만 다른 동일 레이아웃이라
/// `kind` 파라미터 하나로 그린다. 이용권 미차감 안내(서버 자동 환불) 포함.
/// X(닫기)·중단하기(공통)·이어서 진행하기(network) 모두 delegate 신호만 — 이탈·재개는 부모 몫.
@Reducer
public struct InterviewFailureFeature {
    @ObservableState
    public struct State: Equatable {
        public var kind: InterviewFailureKind

        public init(kind: InterviewFailureKind) {
            self.kind = kind
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            /// «중단하기» — X 와 같은 이탈(STT·network 하단 버튼).
            case userTappedAbort
            /// 좌상단 X.
            case userTappedClose
            /// network 전용 «이어서 진행하기».
            case userTappedResume
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {}

        /// 부모 통보. 부모는 이것만 매칭한다 (D1) — kind 별 부모가 다르다:
        /// STT·질문 준비는 코디네이터(화면 교체), network 는 세션(@Presents 오버레이 — [[interview#세션]]).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// X·중단하기 — 면접 흐름 이탈. dismiss 는 상위 몫.
            case closeRequested
            /// 이어서 진행하기(network 전용) — 세션이 실패 지점부터 재개한다.
            case resumeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.userTappedAbort), .view(.userTappedClose):
                return .send(.delegate(.closeRequested))
            case .view(.userTappedResume):
                return .send(.delegate(.resumeRequested))
            case .inner, .delegate:
                return .none
            }
        }
    }
}
