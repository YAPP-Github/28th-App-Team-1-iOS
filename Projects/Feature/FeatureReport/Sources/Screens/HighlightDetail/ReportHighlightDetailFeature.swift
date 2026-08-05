//
//  ReportHighlightDetailFeature.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import Foundation

// @lat: [[report#하이라이트 상세 시트]]
/// 하이라이트 상세 시트 — 화면이 아니라 대본 하이라이트를 탭하면 올라오는 바텀시트.
/// 리포트 카드와 영상 플레이어 STT 오버레이 **양쪽이 이 리듀서를 재사용**한다. 내용은 같고,
/// 차이는 «영상 보러가기» 노출 여부 하나 — 영상이 만료된 리포트에서는 갈 곳이 없어 숨긴다.
///
/// 구성: 분석 내용(강조 문장 + 진단 카드) → 다음 대비 → 마무리 코칭 한 줄.
/// 정답을 주지 않는 제품 원칙에 따라 다음 대비는 답이 아니라 질문으로 끝난다.
///
/// **톤이 다음 대비와 코칭 문구를 가른다** — 부정(Figma 443:7324)은 «질문 의도 ↔ 내 답변» 대조,
/// 긍정(443:7430)은 이어질 수 있는 후속 질문. 분석 내용 블록의 구조는 톤과 무관하게 같다.
@Reducer
public struct ReportHighlightDetailFeature {
    /// 마무리 코칭 문구 — 클라 소유 고정 문구. 부정 톤은 «무엇을 묻고 있는지» 로 갈린다(Figma 443:7324).
    static let improveTipMessage = "다음에는 질문에서 무엇을 묻고 있는지 짚어보세요!"
    /// 마무리 코칭 문구 — 긍정·미지 톤(Figma 443:7430). 미지 톤도 답변을 평하지 않는 이 문구를 쓴다.
    static let neutralTipMessage = "질문의 의도를 떠올리며 답변을 준비해 보세요!"

    /// 다음 대비 블록 — 시안이 톤별로 다른 두 판을 그린다.
    public enum NextPreparation: Equatable, Sendable {
        /// 부정 — 질문이 물은 것과 내가 말한 것을 나란히 놓는다 (Figma 443:7414).
        case intentReview(HighlightContext.IntentReview)
        /// 긍정 — 실전에서 이어질 수 있는 후속 질문 (Figma 443:7519).
        case followUpQuestions([String])

        /// 블록 제목 — 클라 소유 고정 문구. 판이 정하므로 호출부가 넘기지 않는다.
        var heading: String {
            switch self {
            case .intentReview: "질문의 의도를 다시 확인해 보세요"
            case .followUpQuestions: "실전에서는 이런 질문이 이어질 수 있어요"
            }
        }
    }

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

    /// 다음 대비 블록 — 없으면 제목까지 통째로 감춘다.
    ///
    /// 톤이 시안을 가르지만(부정=대조 / 긍정=후속 질문) 두 값 다 서버 확장 대기라 실제 분기는
    /// **온 데이터**가 정한다 — 확장 전후로 코드 경로가 갈리지 않는다. 둘이 함께 오는 톤은 없어
    /// 우선순위는 사실상 무의미하지만, 온다면 톤 전용 판인 대조를 먼저 본다.
    var nextPreparation: ReportHighlightDetailFeature.NextPreparation? {
        if let intentReview = context.intentReview { return .intentReview(intentReview) }
        guard !context.followUpQuestions.isEmpty else { return nil }
        return .followUpQuestions(context.followUpQuestions)
    }

    /// 마무리 코칭 문구 — 톤이 정한다.
    var tipMessage: String {
        switch context.tone {
        case .improve: ReportHighlightDetailFeature.improveTipMessage
        case .good, .unknown: ReportHighlightDetailFeature.neutralTipMessage
        }
    }

    /// 진단 카드 서브타이틀 — 미지 톤은 답변을 평할 근거가 없어 «질문 분석» 으로 남긴다.
    var analysisLabel: String {
        switch context.tone {
        case .good, .improve: "Hilit의 답변 분석"
        case .unknown: "Hilit의 질문 분석"
        }
    }
}
