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
/// 차이는 «이 장면 영상으로 보기» 노출 여부 하나 — 플레이어 안에서 열면 이미 그 장면이라 숨긴다.
///
/// 구성: depth 1 진단(하이라이트 문장 · 행동형 키워드 · 설명) → depth 2 다음 대비(후속 질문).
/// 정답을 주지 않는 제품 원칙에 따라 depth 2 는 답이 아니라 질문으로 끝난다.
@Reducer
public struct ReportHighlightDetailFeature {
    /// depth 2 를 생략할 때 붙이는 마무리 문구 — 잘함이 소진된 경우 (PRD 2-5).
    static let exhaustedMessage = "여기는 면접관이 더 캐물 게 없을 만큼 충분히 답하셨어요."
    /// depth 2 를 생략할 때 붙이는 마무리 문구 — 후속 질문을 걸 재료가 없는 경우.
    static let tooThinMessage = "다음엔 조금 더 자세히 답해보세요."

    @ObservableState
    public struct State: Equatable {
        public let context: HighlightContext
        /// 플레이어 안에서 열면 false — 이미 그 장면에 멈춰 있어 버튼이 무의미하다.
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
            /// 근거 장면으로 이동 — 시트를 닫고 영상으로 넘기는 건 부모 몫.
            case videoJumpRequested(at: TimeInterval)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .none

            case .view(.userTappedVideoJump):
                // 확장 전에는 evidenceAt 이 없어 버튼 자체가 렌더되지 않는다.
                guard let at = state.context.evidenceAt else { return .none }
                return .send(.delegate(.videoJumpRequested(at: at)))

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - 표시 파생값

public extension ReportHighlightDetailFeature.State {
    /// 근거 장면 버튼 노출 조건 — 진입 위치와 시각 유무를 함께 본다.
    var isVideoJumpVisible: Bool { showsVideoJump && context.evidenceAt != nil }

    /// depth 2 표시 여부.
    var hasFollowUpQuestions: Bool { !context.followUpQuestions.isEmpty }

    /// depth 2 를 생략할 때 대신 붙는 마무리 문구.
    /// 잘함이면 «더 캐물 게 없다», 그 외에는 «더 자세히» — 재료 없음의 원인이 다르다 (PRD 2-5).
    var closingMessage: String? {
        guard !hasFollowUpQuestions else { return nil }
        return context.tone == .good
            ? ReportHighlightDetailFeature.exhaustedMessage
            : ReportHighlightDetailFeature.tooThinMessage
    }
}
