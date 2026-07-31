//
//  StartInterviewFeature.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

// @lat: [[home]]
/// 면접 시작 — 홈에서 present 되는 한 장짜리 화면. 시안 3장을 `Variant` 로 분기한다.
///
/// 홈의 phase 가 아니라 별도 Reducer 인 이유: 홈 상태의 표시가 아니라 «면접을 시작할까» 를 묻는
/// 별도 화면이고, 응답(시작·수정)은 홈이 처리할 수 없는 cross-feature 전환이라 delegate 로 올라간다.
@Reducer
public struct StartInterviewFeature {
    /// 시안 3종 — 처음 / 등록 포폴 있음 / 무료 횟수 모두 사용.
    public enum Variant: Equatable, Sendable {
        case first
        case hasPortfolio
        case exhausted
    }

    @ObservableState
    public struct State: Equatable {
        /// 표시할 시안 변형 — present 시점에 홈이 정해서 넘긴다.
        public var variant: Variant

        public init(variant: Variant) {
            self.variant = variant
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            /// [시작하기] 탭.
            case userTappedStart
            /// [수정하기] 탭 — 이전 면접 정보를 고치고 시작한다.
            case userTappedEditInfo
            /// [홈으로] 탭 — 무료 횟수 소진 시안의 나가기 경로.
            case userTappedBackToHome
            /// 내비바 X 탭.
            case userTappedClose
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {}

        /// 부모(HomeFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {
            /// 면접 시작 요청 — 실제 전환은 홈 위로 AppFeature 가 조립한다.
            case startRequested
            /// 면접 정보 수정 요청 — 전환은 AppFeature.
            case editInfoRequested
            /// 닫기 요청 — 홈으로 되돌린다.
            case closeRequested
            /// 홈으로 요청 — 소진 시안의 나가기. 닫기와 같은 결과지만 발원지가 다르다.
            case backToHomeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.userTappedStart):
                return .send(.delegate(.startRequested))
            case .view(.userTappedEditInfo):
                return .send(.delegate(.editInfoRequested))
            case .view(.userTappedBackToHome):
                return .send(.delegate(.backToHomeRequested))
            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))
            case .inner, .delegate:
                return .none
            }
        }
    }
}
