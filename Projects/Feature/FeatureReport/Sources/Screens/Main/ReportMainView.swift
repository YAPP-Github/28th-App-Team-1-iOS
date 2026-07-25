//
//  ReportMainView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

// 1차 리포트. 구조(한 줄 요약 → 레드플래그 줄 → 영상 CTA → 카드 → 지인 보내기)만 세운 상태로,
// 레이아웃 수치·카드 스타일은 Figma 연결 시 확정한다 (정의서 §10). 색·타이포는 전부 DS 토큰.
@ViewAction(for: ReportMainFeature.self)
public struct ReportMainView: View {
    @Bindable public var store: StoreOf<ReportMainFeature>

    public init(store: StoreOf<ReportMainFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { send(.onAppear) }
        .sheet(item: $store.scope(state: \.highlightDetail, action: \.highlightDetail)) { store in
            ReportHighlightDetailView(store: store)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.loadState {
        case .loading:
            statusMessage("리포트를 만들고 있어요.", showsProgress: true)
        case .loaded:
            reportBody
        case .pollTimedOut:
            statusMessage("채점이 예상보다 오래 걸리고 있어요.\n잠시 후 다시 확인해 주세요.", showsProgress: false)
        case let .failed(error):
            statusMessage(message(for: error), showsProgress: false)
        }
    }

    private var reportBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headline
                redFlagNotices
                watchVideoButton
                cards
                peerFeedbackButton
                if store.isInsufficient {
                    retryButton
                }
            }
            .padding(.ds(.p20))
        }
    }

    // MARK: - 상단

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                send(.userTappedClose)
            } label: {
                Image.Ic.close
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.HilitBlack.b800)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }

    /// 한 줄 요약 — 서버 소유 문구. nil 이면 분석 부족 폴백만 쓴다 (정의서 §6).
    private var headline: some View {
        Text(store.report?.headline ?? ReportMainView.headlineFallback)
            .dsTypography(.head3)
            .foregroundStyle(Color.Gray.g800)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var redFlagNotices: some View {
        ForEach(Array(store.visibleRedFlagNotices.enumerated()), id: \.offset) { _, notice in
            Text(notice.message)
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g600)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private var watchVideoButton: some View {
        if store.playableVideoURL != nil {
            PrimaryButton("영상 다시보기") { send(.userTappedWatchVideo) }
        } else {
            Text(ReportMainView.videoExpiredMessage)
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g500)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var peerFeedbackButton: some View {
        PrimaryButton("지인에게 면접 영상 보내기") { send(.userTappedPeerFeedback) }
    }

    private var retryButton: some View {
        PrimaryButton("다시 연습하기") { send(.userTappedRetry) }
    }

    // MARK: - 카드

    /// 서버 배열 순서가 계약이라 재정렬하지 않고, id 도 인덱스를 쓴다 (정의서 §9-2).
    private var cards: some View {
        ForEach(Array(store.cards.enumerated()), id: \.offset) { cardIndex, card in
            cardView(card, cardIndex: cardIndex)
        }
    }

    private func cardView(_ card: InterviewReportCard, cardIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.displayTitle)
                .dsTypography(.sub7)
                .foregroundStyle(Color.Gray.g800)

            if let questionText = card.questionText {
                Text(questionText)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.Gray.g800)
            }
            if let questionIntent = card.questionIntent {
                Text(questionIntent)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.Gray.g500)
            }
            // 해상도 낮음 안내 — 서버 소유 문구. 이 카드는 하이라이트가 없어 시트로 안 간다.
            if let resolutionNotice = card.resolutionNotice {
                Text(resolutionNotice)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.Gray.g600)
            }
            // 카드 레드플래그 — 해상도와 독립이라 해상도 낮음 카드에도 표기한다.
            ForEach(Array((card.cardRedFlagNotices ?? []).enumerated()), id: \.offset) { _, notice in
                Text(notice.message)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.Gray.g600)
            }
            transcript(card, cardIndex: cardIndex)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.ds(.p16))
        .background(Color.Gray.g50)
    }

    /// 대본 + 하이라이트. 지금은 문장 단위 버튼 나열이고, sub-range 강조는
    /// `AttributedString` 기반 컴포넌트로 Figma 확정 후 교체한다 (정의서 §10).
    @ViewBuilder
    private func transcript(_ card: InterviewReportCard, cardIndex: Int) -> some View {
        if let transcript = card.transcript {
            Text(transcript)
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g800)
                .fixedSize(horizontal: false, vertical: true)
        }
        ForEach(Array((card.highlightSpans ?? []).enumerated()), id: \.offset) { spanIndex, span in
            if let sentence = card.sentence(for: span) {
                Button {
                    send(.userTappedHighlight(cardIndex: cardIndex, spanIndex: spanIndex))
                } label: {
                    Text(sentence)
                        .dsTypography(.body3)
                        .foregroundStyle(color(for: span.highlightTone))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 보조

    private func statusMessage(_ message: String, showsProgress: Bool) -> some View {
        VStack(spacing: 12) {
            Spacer()
            if showsProgress {
                ProgressView()
            }
            Text(message)
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g600)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.ds(.p20))
    }

    /// 미지 톤은 강조하지 않는다 — 모르는 값을 개선으로 오인해 빨갛게 칠하지 않기 위해서.
    private func color(for tone: HighlightTone) -> Color {
        switch tone {
        case .good: Color.Positive.p800
        case .improve: Color.Error.e500
        case .unknown: Color.Gray.g800
        }
    }

    private func message(for error: InterviewReportError) -> String {
        switch error {
        case .sessionNotFound: "리포트를 찾을 수 없어요."
        case .networkFailure: "네트워크 연결을 확인해 주세요."
        default: "리포트를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요."
        }
    }

    /// 서버 `headline` 이 비었을 때의 폴백 (정의서 §6).
    static let headlineFallback = "이번 면접의 답변이 충분하지 않아요. 다음 면접 연습 때는 조금 더 충분한 답변을 말씀해주세요."
    /// 영상 만료 안내 — 클라 소유 문구.
    static let videoExpiredMessage = "24시간이 지나서 영상이 사라졌어요. "
        + "다음 면접 연습 때는 지인 피드백을 받아보세요. 더 오랫동안 영상을 볼 수 있어요."
}

#Preview("1차 리포트") {
    ReportMainView(
        store: Store(initialState: ReportMainFeature.State(sessionId: 1)) {
            ReportMainFeature()
        }
    )
}
