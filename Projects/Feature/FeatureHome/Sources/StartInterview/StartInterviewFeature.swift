//
//  StartInterviewFeature.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

// @lat: [[home]]
/// 면접 시작 — 홈 씬에서 리포트 시트 뒤에 깔리는 한 겹. 시안 3장을 `Variant` 로 분기한다.
///
/// 홈의 phase 가 아니라 별도 Reducer 인 이유: 홈 상태의 표시가 아니라 «면접을 시작할까» 를 묻는
/// 별도 화면이고, 응답(시작·이어서 진행)은 홈이 처리할 수 없는 cross-feature 전환이라 delegate 로 올라간다.
///
/// 나가기는 여기 없다 — 이 겹을 덮는 건 «시트를 도로 올린다» 라서 홈의 자리(`SheetDetent`) 몫이다.
/// 하단 «홈으로» 만 delegate 로 올린다(CTA 는 이 화면 소유라서).
@Reducer
public struct StartInterviewFeature {
    /// 시안 3종 — 처음 / 진행 중 면접 있음 / 무료 횟수 모두 사용.
    ///
    /// 회차를 묻지 않는다 — 포폴 보유 여부로 «2회차» 를 가르던 분기는 걷어냈다(제품 결정 2026-08-08).
    ///
    /// `inProgress` 의 재료는 **서버가 아니라 로컬 보관값**이다 — 진행 중 세션 목록 API 가 없어
    /// 클라가 세션 생성 시 보관한 sessionId 의 존재로 판정하고(`HeldSessionStore`), 남은 질문 수도
    /// 녹화 길이에서 rule-base 로 환산한다(둘 다 `HomeFeature.startVariant`).
    public enum Variant: Equatable, Sendable {
        case first
        /// 진행 중(held) 면접이 있다 — 남은 질문 수는 그 세션의 값이다.
        case inProgress(remainingQuestionCount: Int)
        case exhausted
    }

    @ObservableState
    public struct State: Equatable {
        /// 표시할 시안 변형 — 홈 진입 로드 결과로 홈이 정한다(잔여 0 이면 소진).
        public var variant: Variant
        /// «처음부터 시작하시겠어요?» 확인 단계에 들어와 있는가 — `.inProgress` 밖에선 의미가 없다.
        ///
        /// **별도 화면이 아니라 이 겹의 한 단계**다(시안 443:5873): 배경·내비바는 그대로고 인사말·카드·CTA
        /// 세 자리만 갈린다. 화면을 새로 띄우면 배경 커튼이 두 겹으로 그려지고 나가기(X)도 둘이 된다.
        public var isConfirmingRestart: Bool
        /// 인사말에 넣는 사용자 이름 — 홈이 프로필 로드 결과를 그대로 내려 준다.
        /// 응답 전엔 비어 있고, 그때는 뷰가 이름 줄을 뺀다(사람 이름을 기본값으로 두지 않는다).
        public var userName: String
        /// 남은 무료 면접 횟수 — 서버 값 표시만(«진실은 서버에만», docs/work/home-account.md §3).
        /// **nil 은 «아직 모른다»** 다(프로필 응답 전·실패). 0 과 갈라 둬야 로드 실패를 소진으로
        /// 오해하지 않는다 — 없는 조각은 가짜 값을 만들지 않고 뷰가 그 조각만 뺀다.
        public var remainingChances: Int?

        /// 기본값은 전부 중립이다 — `variant` 로 시안 값을 파생하지 않는다.
        /// 파생하면 프리뷰 픽스처(이름 «재원», 조작된 잔여 3회)가 앱에서 그대로 그려진다.
        /// 시안대로 보고 싶은 프리뷰가 픽스처를 명시로 넘긴다.
        /// 잔여의 중립은 **0 이 아니라 nil** 이다 — 0 은 «소진» 이라는 서버 판정이라서.
        public init(
            variant: Variant,
            isConfirmingRestart: Bool = false,
            userName: String = "",
            remainingChances: Int? = nil
        ) {
            self.variant = variant
            self.isConfirmingRestart = isConfirmingRestart
            self.userName = userName
            self.remainingChances = remainingChances
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
            /// 진행 중 시안의 [처음부터 시작] 탭 — 곧장 버리지 않고 확인 단계로 들어간다.
            case userTappedRestart
            /// 확인 단계의 [뒤로가기] 탭 — 확인만 접고 진행 중 시안으로 돌아간다.
            case userTappedRestartCancel
            /// 확인 단계의 [처음부터 시작] 탭 — 여기서야 확정이다.
            case userTappedRestartConfirm
            /// [이어서 진행] 탭 — 진행 중인 세션으로 돌아간다.
            case userTappedResume
            /// [홈으로] 탭 — 무료 횟수 소진 시안의 나가기 경로.
            case userTappedBackToHome
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {}

        /// 부모(HomeFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {
            /// 면접 시작 요청 — 실제 전환은 홈 위로 AppFeature 가 조립한다.
            case startRequested
            /// 처음부터 시작 확정 — **확인 단계를 통과한 뒤에만** 나간다. 전환은 AppFeature.
            case restartRequested
            /// 이어서 진행 요청 — 진행 중 세션 복귀. 전환은 AppFeature.
            case resumeRequested
            /// 홈으로 요청 — 소진 시안의 나가기(하단 CTA). 홈은 시트를 도로 올린다.
            case backToHomeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.userTappedStart):
                return .send(.delegate(.startRequested))
            case .view(.userTappedRestart):
                // 이 탭은 아직 요청이 아니다 — 진행분을 버리는 일이라 한 번 되묻는다(시안 443:5873).
                state.isConfirmingRestart = true
                return .none
            case .view(.userTappedRestartCancel):
                state.isConfirmingRestart = false
                return .none
            case .view(.userTappedRestartConfirm):
                // 확인은 여기서 접지 않는다 — 되돌아오는 자리(시트 복귀)가 홈에 있고,
                // 여기서 끄면 화면이 넘어가는 동안 진행 중 시안이 한 프레임 스친다.
                return .send(.delegate(.restartRequested))
            case .view(.userTappedResume):
                return .send(.delegate(.resumeRequested))
            case .view(.userTappedBackToHome):
                return .send(.delegate(.backToHomeRequested))
            case .inner, .delegate:
                return .none
            }
        }
    }
}
