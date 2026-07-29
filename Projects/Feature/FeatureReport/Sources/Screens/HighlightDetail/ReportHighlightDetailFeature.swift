//
//  ReportHighlightDetailFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import Foundation

// @lat: [[report#하이라이트 상세 시트]]
/// 하이라이트 상세 시트 — 화면이 아니라 대본 하이라이트를 탭하면 올라오는 바텀시트.
/// 리포트 카드와 영상 플레이어 STT 오버레이 **양쪽이 이 리듀서를 재사용**한다. 내용은 같고,
/// 차이는 «영상 보러가기» 노출 여부 하나 — 영상이 만료된 리포트에서는 갈 곳이 없어 숨긴다.
///
/// 구성: 분석 내용(강조 문장 + 진단 카드) → 다음 대비(후속 질문) → 마무리 코칭 한 줄.
/// 정답을 주지 않는 제품 원칙에 따라 다음 대비는 답이 아니라 질문으로 끝난다.
@Reducer
public struct ReportHighlightDetailFeature {
    /// 시트 마무리 코칭 문구 — 클라 소유 고정 문구(Figma 3165:13129 · 3165:13462).
    /// 개편 전에는 톤별로 두 문구였는데(PRD 2-5), 현재 디자인은 톤과 무관하게 한 문구로 통합됐다.
    static let tipMessage = "질문의 의도를 떠올리며 답변을 준비해 보세요!"

    @ObservableState
    public struct State: Equatable {
        public let context: HighlightContext
        /// 재생 가능한 영상이 있을 때만 true — 없으면 «영상 보러가기» 를 숨긴다.
        public let showsVideoJump: Bool

        public init(context: HighlightContext, showsVideoJump: Bool) {
            self.context = context
            self.showsVideoJump = showsVideoJump
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        public enum View: Equatable, Sendable {
            case onAppear
            case userTappedVideoJump
        }

        /// 부모(리포트 메인 / 플레이어) 통보.
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 영상으로 이동 — 시트를 닫고 영상으로 넘기는 건 부모 몫.
            /// `at` 이 nil 이면 근거 시각을 모른다는 뜻이라 처음부터 재생한다 (서버 timestamp 확장 대기).
            case videoJumpRequested(at: TimeInterval?)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .none

            case .view(.userTappedVideoJump):
                return .send(.delegate(.videoJumpRequested(at: state.context.evidenceAt)))

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - 표시 파생값

public extension ReportHighlightDetailFeature.State {
    /// 영상 진입 버튼 노출 조건. 근거 시각(`evidenceAt`)이 없어도 처음부터 볼 수 있으므로
    /// 영상 재생 가능 여부만 본다.
    var isVideoJumpVisible: Bool { showsVideoJump }

    /// 다음 대비 블록 표시 여부 — 후속 질문이 없으면 블록째 렌더하지 않는다.
    var hasFollowUpQuestions: Bool { !context.followUpQuestions.isEmpty }
}
