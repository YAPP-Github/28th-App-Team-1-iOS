//
//  ReportHighlightDetailView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

// Figma: «Report_HighlightDetail_Sheet»
//        부정 https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-7324
//        긍정 https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-7430

import ComposableArchitecture
import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

/// 하이라이트 상세 바텀시트 — `Report_Main_Default` 의 대본 하이라이트를 탭하면 아래에서 올라온다.
/// 부모가 `.sheet(item:)` 으로 제시하고, 이 뷰는 detent·배경·그래버만 지정한다.
///
/// 세로 구성: 그래버 → 분석 내용(문맥 흐린 대본 + 진단 카드) → 다음 대비 → 마무리 코칭.
/// **톤은 «분석 내용» 이 아니라 그 아래를 가른다** — 진단 카드의 아이콘(부정 problem / 긍정 success)과
/// 다음 대비 판, 코칭 문구가 갈리고 블록 순서·간격은 두 시안이 같다.
@ViewAction(for: ReportHighlightDetailFeature.self)
public struct ReportHighlightDetailView: View {
    /// Figma 시트 최대 높이 674 / 화면 812 비율.
    private static let detentFraction = 0.83

    @Bindable public var store: StoreOf<ReportHighlightDetailFeature>

    public init(store: StoreOf<ReportHighlightDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            grabber
            ScrollView {
                // @ds(spacing): 48 — 분석 내용 ↔ 다음 대비 사이 (spacing 스케일에 48 이 없다)
                VStack(alignment: .leading, spacing: 48) {
                    analysisSection
                    nextPreparationSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Figma pl20 / pr14 — 오른쪽은 스크롤 인디케이터 자리를 비워 둔다.
                .padding(.leading, .ds(.p20))
                .padding(.trailing, .ds(.p14))
                .padding(.top, .ds(.p24))
                // 시안은 판이 콘텐츠에 딱 맞지만 스크롤 끝이 홈 인디케이터에 붙어 보여 여백을 둔다.
                .padding(.bottom, .ds(.p24))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.HilitBlack.b900)
        // 다크 판 선언 — 하위 DS 버튼 스타일이 다크 팔레트로 풀린다(버튼마다 넘기지 않는다).
        .hilitSurface(.dark)
        .presentationDetents([.fraction(Self.detentFraction), .large])
        // 시스템 인디케이터는 규격이 시안과 달라 숨기고 그래버를 직접 그린다(`hilitDetentSheet` 와 같은 판단).
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.HilitBlack.b900)
        .onAppear { send(.onAppear) }
    }

    // @ds(component): 시트 그래버 — 60×5 g400 바(모서리 0) + 행 높이 20. 공용 컴포넌트 없음
    private var grabber: some View {
        Rectangle()
            .fill(Color.GrayScale.g400)
            .frame(width: 60, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: 20)
    }

    // MARK: - 분석 내용

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            HStack(spacing: 0) {
                Text("분석 내용")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
                Spacer(minLength: .ds(.p8))
                if store.isVideoJumpVisible {
                    videoJumpButton
                }
            }

            VStack(alignment: .leading, spacing: .ds(.p16)) {
                // 강조 구간만 톤 색으로 살리고 나머지 문맥은 흐린 회색 — 시트 안에서는 탭 대상이 아니다.
                TranscriptText(
                    transcript: store.context.transcript,
                    spans: [store.context.span],
                    baseColor: Color.GrayScale.g600
                )
                if let analysis = store.context.analysis {
                    // 볼드 한 줄(Figma «명확한 원인과 구조 설명» / «질문 의도와 다르게 답변») = 행동형
                    // 키워드 — 서버 확장 전에는 nil 이라 카드가 그 줄만 빼고 그린다.
                    MessageCard(
                        .detail(
                            subtitle: store.analysisLabel,
                            title: store.context.keyword,
                            contents: analysis
                        ),
                        icon: analysisIcon
                    )
                }
            }
        }
    }

    /// DS «button-mini/with-icon» 그대로 — 아이콘은 변형이 아니라 라벨 구성이라 여기서 조립한다.
    /// 시트 루트가 `.hilitSurface(.dark)` 를 선언해 `.gray` 가 다크 판(g900 바탕 + 흰 라벨)으로 풀린다.
    private var videoJumpButton: some View {
        Button {
            send(.userTappedVideoJump)
        } label: {
            HStack(spacing: .ds(.p8)) {
                // 시안 레이어명은 `video/16px/default` 인데 실제로 흰 글리프로 그려져 있어 흰 에셋을 쓴다.
                Image.Video.white16
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text("영상 보러가기")
            }
        }
        .buttonStyle(.mini(.gray, layout: .withIcon))
    }

    // MARK: - 다음 대비

    private var nextPreparationSection: some View {
        VStack(alignment: .leading, spacing: .ds(.p16)) {
            // 대조·후속 질문 다 서버 확장 대기라 지금은 비어 온다 — 비면 제목까지 통째로 감춘다.
            if let nextPreparation = store.nextPreparation {
                Text(nextPreparation.heading)
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
                    .fixedSize(horizontal: false, vertical: true)

                switch nextPreparation {
                case let .intentReview(intentReview):
                    intentReviewBlock(intentReview)
                case let .followUpQuestions(questions):
                    followUpQuestionsBlock(questions)
                }
            }

            MessageCard(.mini(store.tipMessage))
        }
    }

    /// 부정 톤 — 질문이 물은 것과 내가 말한 것을 구분선으로 갈라 나란히 놓는다.
    private func intentReviewBlock(_ intentReview: HighlightContext.IntentReview) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p14)) {
            VStack(alignment: .leading, spacing: .ds(.p10)) {
                TagLabel("질문 의도", style: .darkGrayGray, size: .regular)
                VStack(alignment: .leading, spacing: .ds(.p8)) {
                    bodyLine(intentReview.intent)
                    Text(intentReview.question)
                        .dsTypography(.body7)
                        .foregroundStyle(Color.GrayScale.g200)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HilitDivider()

            VStack(alignment: .leading, spacing: .ds(.p10)) {
                TagLabel("내 답변", style: .darkGrayGreen, size: .regular)
                bodyLine(intentReview.answerTopic)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 시트 본문 한 줄 — 대조 블록의 요약과 후속 질문이 같은 규격이다(body3 · Gray scale/100).
    private func bodyLine(_ text: String) -> some View {
        Text(text)
            .dsTypography(.body3)
            // @ds(color): #F3F4F6 (Figma Gray scale/100) → GrayScale.g50 — 다크 시트 본문, 팔레트에 없는 단계
            .foregroundStyle(Color.GrayScale.g50)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 긍정 톤 — 실전에서 이어질 수 있는 질문. 정답이 아니라 질문으로 끝난다.
    private func followUpQuestionsBlock(_ questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p12)) {
            ForEach(Array(questions.enumerated()), id: \.offset) { _, question in
                HStack(alignment: .top, spacing: .ds(.p8)) {
                    // 판 색이 에셋에 구워져 있다 — 틴트하지 않는다.
                    Image.Q.default
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    bodyLine(question)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 진단 카드 아이콘 — 미지 톤은 판단을 붙이지 않는 중립 아이콘으로 둔다.
    private var analysisIcon: Image {
        switch store.context.tone {
        case .good: Image.HilitAnalyze.success
        case .improve: Image.HilitAnalyze.problem
        case .unknown: Image.HilitAnalyze.question
        }
    }
}

#Preview("상세 시트 — 부정(질문 의도 대조)") {
    ReportHighlightDetailView(
        store: Store(
            initialState: ReportHighlightDetailFeature.State(
                context: HighlightContext(
                    transcript: "대학교에서는 시각디자인을 전공하며, 음 디자인 동아리 활동과 여러 공모전에 도전하면서 회사 일 감각을 키워왔습니다.",
                    span: HighlightSpan(
                        startIndex: 20,
                        endIndex: 59,
                        tone: "IMPROVE",
                        analysis: "질문 의도와 맞지 않는 답변입니다. 실무 경험 사례를 구체적으로 설명해 보세요."
                    ),
                    keyword: "질문 의도와 다르게 답변",
                    intentReview: HighlightContext.IntentReview(
                        intent: "장애 원인을 좁혀가는 순서",
                        question: "Q. 앱 업데이트 이후 성능이 저하되었습니다. 가장 먼저 확인할 항목은 무엇인가요?",
                        answerTopic: "팀 내 신뢰와 성향"
                    )
                ),
                showsVideoJump: true
            )
        ) {
            ReportHighlightDetailFeature()
        }
    )
}

#Preview("상세 시트 — 긍정(후속 질문)") {
    ReportHighlightDetailView(
        store: Store(
            initialState: ReportHighlightDetailFeature.State(
                context: HighlightContext(
                    transcript: "프로파일링하니 DB 왕복 7번이 원인이라, 안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요.",
                    span: HighlightSpan(
                        startIndex: 8,
                        endIndex: 51,
                        tone: "GOOD",
                        analysis: "문제를 바라보는 관점이 좋았어요. 원인과 한계까지 함께 설명해 설득력이 높았습니다."
                    ),
                    keyword: "명확한 원인과 구조 설명",
                    followUpQuestions: ["그 캐시가 깨지는 지점은 어디였고, 정합성은 어떻게 지켰나요?"]
                ),
                showsVideoJump: true
            )
        ) {
            ReportHighlightDetailFeature()
        }
    )
}

#Preview("상세 시트 — 서버 확장 전(다음 대비 없음·영상 만료)") {
    ReportHighlightDetailView(
        store: Store(
            initialState: ReportHighlightDetailFeature.State(
                context: HighlightContext(
                    transcript: "대학교에서는 시각디자인을 전공하며, 음 디자인 동아리 활동과 여러 공모전에 도전하면서 회사 일 감각을 키워왔습니다.",
                    span: HighlightSpan(
                        startIndex: 20,
                        endIndex: 59,
                        tone: "IMPROVE",
                        analysis: "질문 의도와 맞지 않는 답변입니다. 실무 경험 사례를 구체적으로 설명해 보세요."
                    )
                ),
                showsVideoJump: false
            )
        ) {
            ReportHighlightDetailFeature()
        }
    )
}
