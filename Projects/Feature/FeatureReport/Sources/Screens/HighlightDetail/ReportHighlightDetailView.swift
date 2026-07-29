//
//  ReportHighlightDetailView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

/// 하이라이트 상세 바텀시트 — Figma «Report_HighlightDetail_Sheet»(부정 3165:13129 · 긍정 3165:13462).
/// 부모가 `.sheet(item:)` 으로 제시하고, 이 뷰는 detent·배경만 지정한다.
///
/// 분석 내용(문맥 흐린 대본 + 진단 카드) → 다음 대비(후속 질문) → 마무리 코칭 순서.
/// 톤(잘함/개선)은 강조 색과 진단 카드 아이콘만 가른다 — 구조는 같다.
@ViewAction(for: ReportHighlightDetailFeature.self)
public struct ReportHighlightDetailView: View {
    /// Figma 시트 최대 높이 674 / 화면 812 비율.
    private static let detentFraction = 0.83

    @Bindable public var store: StoreOf<ReportHighlightDetailFeature>

    public init(store: StoreOf<ReportHighlightDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                analysisSection
                nextPreparationSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Figma pl20 / pr14 — 오른쪽은 스크롤 인디케이터 자리를 비워 둔다.
            .padding(.leading, .ds(.p20))
            .padding(.trailing, .ds(.p14))
            .padding(.vertical, .ds(.p24))
        }
        .background(Color.HilitBlack.b900)
        // 다크 판 선언 — 하위 DS 버튼 스타일이 다크 팔레트로 풀린다(버튼마다 넘기지 않는다).
        .hilitSurface(.dark)
        .presentationDetents([.fraction(Self.detentFraction), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.HilitBlack.b900)
        .onAppear { send(.onAppear) }
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
                    // 볼드 한 줄(Figma «명확한 원인과 구조 설명») = 행동형 키워드 —
                    // 서버 확장 전에는 nil 이라 카드가 그 줄만 빼고 그린다.
                    AnalysisCard(
                        kind: analysisKind,
                        title: store.context.keyword,
                        contents: analysis
                    )
                }
            }
        }
    }

    /// DS «button-mini/with-icon» 그대로 — 아이콘은 변형이 아니라 라벨 구성이라 여기서 조립한다.
    /// 시트 루트가 `.hilitSurface(.dark)` 를 선언해 `.gray` 가 다크 팔레트(g900 바탕)로 풀린다.
    /// (Figma 는 라벨을 흰색으로 그렸는데 DS 다크 mini/gray 는 g300 이다 — 카탈로그를 따랐다.)
    private var videoJumpButton: some View {
        Button {
            send(.userTappedVideoJump)
        } label: {
            HStack(spacing: .ds(.p8)) {
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
            // 후속 질문은 서버 확장 대기라 지금은 비어 온다 — 비면 제목까지 통째로 감춘다.
            if store.hasFollowUpQuestions {
                Text("실전에서는 이런 질문이 이어질 수 있어요")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: .ds(.p12)) {
                    ForEach(Array(store.context.followUpQuestions.enumerated()), id: \.offset) { _, question in
                        followUpQuestion(question)
                    }
                }
            }

            AnalysisTipCard(message: ReportHighlightDetailFeature.tipMessage)
        }
    }

    private func followUpQuestion(_ question: String) -> some View {
        HStack(alignment: .top, spacing: .ds(.p8)) {
            Image.Q.default
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(question)
                .dsTypography(.body3)
                // @ds(color): #F3F4F6 (Figma Gray scale/100) → GrayScale.g50 — 다크 시트 본문 텍스트, 팔레트에 s계열 없음
                .foregroundStyle(Color.GrayScale.g50)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 진단 카드 아이콘 — 미지 톤은 판단을 붙이지 않는 중립 아이콘으로 둔다.
    private var analysisKind: AnalysisCard.Kind {
        switch store.context.tone {
        case .good: .strength
        case .improve: .improvement
        case .unknown: .question
        }
    }
}

#Preview("상세 시트 — 개선") {
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
                showsVideoJump: true
            )
        ) {
            ReportHighlightDetailFeature()
        }
    )
}

#Preview("상세 시트 — 잘함") {
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
                    followUpQuestions: ["그 캐시가 깨지는 지점은 어디였고, 정합성은 어떻게 지켰나요?"]
                ),
                showsVideoJump: true
            )
        ) {
            ReportHighlightDetailFeature()
        }
    )
}
