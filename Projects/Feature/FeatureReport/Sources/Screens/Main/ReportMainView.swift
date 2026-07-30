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

/// 1차 리포트 — Figma «Report_Main_Default»(3165:14385). 다크 화면(b900) 기준.
///
/// 세로 구성: 한 줄 요약 → 영상 카드 → 상세 리포트(질문 탭 + 선택 카드) → 지인 피드백.
/// 카드를 세로로 늘어놓지 않고 **질문 탭으로 한 장씩** 보여준다 — 대본이 길어 전부 펼치면 스크롤이 무너진다.
/// 색·타이포는 전부 DS 토큰이고, 사용자 문구는 대부분 서버 소유다 (정의서 §6).
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.HilitBlack.b900.ignoresSafeArea())
        // 다크 판 선언 — 하위 `.mini`(재시도 버튼·지인 이름 탭)의 팔레트가 다크용으로 바뀐다.
        .hilitSurface(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear { send(.onAppear) }
        .sheet(item: $store.scope(state: \.highlightDetail, action: \.highlightDetail)) { store in
            ReportHighlightDetailView(store: store)
        }
    }

    /// 상태 분기 (정의서 §4-4) — 폴링 지연·재시도 가능 에러는 수동 재시도 버튼을 붙이고,
    /// 복구 불가 에러(세션 없음·타인 소유, 로그인 만료)는 닫기만 남긴다.
    @ViewBuilder
    private var content: some View {
        switch store.loadState {
        case .loading:
            statusMessage("리포트를 만들고 있어요.", showsProgress: true)
        case .loaded:
            reportBody
        case .pollTimedOut:
            statusMessage(
                "채점이 예상보다 오래 걸리고 있어요.\n잠시 후 다시 확인해 주세요.",
                showsRetry: true
            )
        case let .failed(error):
            statusMessage(message(for: error), showsRetry: isRetryable(error))
        }
    }

    private var reportBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                headline
                videoSection
                divider
                detailReportSection
                peerFeedbackSection
                if store.isInsufficient {
                    retryButton
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            .padding(.top, .ds(.p10))
            .padding(.bottom, .ds(.p24))
        }
    }

    // MARK: - 상단

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.white24
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .ds(.p20))
        .frame(height: 54)
    }

    /// 한 줄 요약 — 서버 소유 문구. nil 이면 분석 부족 폴백만 쓴다 (정의서 §6).
    private var headline: some View {
        Text(store.report?.headline ?? ReportMainView.headlineFallback)
            .dsTypography(.head3)
            .foregroundStyle(Color.BlackWhite.white)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.GrayScale.g800)
            .frame(height: .ds(.small))
    }

    // MARK: - 영상

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: .ds(.p12)) {
            VideoCountdownCard(
                expiresAt: store.report?.video?.expiresAt,
                isExpired: store.playableVideoURL == nil,
                onTap: { send(.userTappedWatchVideo) }
            )
            // 시청 시간 연장 안내 — 이미 피드백이 도착했으면 연장이 끝난 얘기라 감춘다.
            if !store.hasGuestFeedback {
                Text(ReportMainView.videoExtensionNotice)
                    .dsTypography(.body9)
                    .foregroundStyle(Color.GrayScale.g600)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 상세 리포트

    private var detailReportSection: some View {
        VStack(alignment: .leading, spacing: 34) {
            VStack(alignment: .leading, spacing: .ds(.p10)) {
                detailReportHeader
                QuestionTabBar(
                    cards: store.cards,
                    selectedIndex: store.selectedCardIndex,
                    onSelect: { send(.userTappedQuestionTab($0)) }
                )
            }
            if let card = store.selectedCard {
                selectedCardBody(card)
            }
        }
    }

    /// 제목 + 레드플래그 느낌표. 툴팁은 오버레이라 열고 닫아도 아래 내용이 밀리지 않는다.
    private var detailReportHeader: some View {
        HStack(spacing: .ds(.p8)) {
            Text("상세 리포트")
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)

            if store.hasRedFlagNotices {
                Button {
                    send(.userTappedRedFlagInfo)
                } label: {
                    Image.Issue.error16
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .topLeading) {
            if store.hasRedFlagNotices, store.isRedFlagTooltipVisible {
                BubbleField(store.redFlagTooltipMessage, .mini(mood: .dark))
                    // 가로는 섹션 폭에 맞추고 세로만 내용대로 늘린다 — 안내 문구가 길어 한 줄로 두면
                    // 말풍선이 화면 밖으로 나간다(툴팁 변형은 내용 폭이라 스스로 줄바꿈하지 않는다).
                    .fixedSize(horizontal: false, vertical: true)
                    // 말풍선 아래끝이 제목 위에 오도록 자기 높이만큼 끌어올린다 (Figma 오버레이 배치).
                    .alignmentGuide(.top) { $0[.bottom] + .ds(.p4) }
            }
        }
    }

    private func selectedCardBody(_ card: InterviewReportCard) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p24)) {
            VStack(alignment: .leading, spacing: .ds(.p16)) {
                questionRow(card)

                // 질문 의도 분석 — 서버 소유 문구.
                if let questionIntent = card.questionIntent {
                    AnalysisCard(kind: .question, contents: questionIntent)
                }
                // 해상도 낮음 안내 — 이 카드는 하이라이트가 없어 시트로 가지 않는다.
                if let resolutionNotice = card.resolutionNotice {
                    AnalysisCard(kind: .improvement, contents: resolutionNotice)
                }
                // 카드 레드플래그 — 해상도와 독립이라 해상도 낮음 카드에도 표기한다.
                ForEach(Array((card.cardRedFlagNotices ?? []).enumerated()), id: \.offset) { _, notice in
                    AnalysisCard(kind: .improvement, contents: notice.message)
                }
            }

            if let transcript = card.transcript {
                TranscriptText(
                    transcript: transcript,
                    spans: card.highlightSpans ?? [],
                    onTapSpan: { spanIndex in
                        send(.userTappedHighlight(cardIndex: store.selectedCardIndex, spanIndex: spanIndex))
                    }
                )
            }
        }
    }

    /// 질문 배지 + 질문 원문. 질문이 비면 배지만 덩그러니 남으므로 행째 렌더하지 않는다.
    @ViewBuilder
    private func questionRow(_ card: InterviewReportCard) -> some View {
        if let questionText = card.questionText {
            HStack(alignment: .top, spacing: .ds(.p8)) {
                Image.Q.default
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Text(questionText)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.BlackWhite.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 지인 피드백

    /// 아직 아무도 안 남겼으면 «보내기» 카드, 한 명이라도 남겼으면 그 사람들의 평가를 보여준다.
    private var peerFeedbackSection: some View {
        VStack(alignment: .leading, spacing: store.hasGuestFeedback ? .ds(.p10) : .ds(.p16)) {
            Text("지인 피드백")
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)

            if store.hasGuestFeedback {
                GuestFeedbackPanel(
                    guests: store.guests,
                    selectedIndex: store.selectedGuestIndex,
                    expandedAxes: store.expandedCommentAxes,
                    onSelectGuest: { send(.userTappedGuestTab($0)) },
                    onToggleComment: { send(.userTappedAttitudeComment(axisCode: $0)) }
                )
            } else {
                PeerFeedbackCard(
                    participantCount: store.guestParticipantCount,
                    maxCount: ReportMainFeature.maxGuestCount,
                    onTap: { send(.userTappedPeerFeedback) }
                )
            }
        }
    }

    /// 분석 부족 안내 CTA. 스크롤 내용의 일부라 하단 도킹형(`.bottom` — 안전영역까지 번짐)이 아니라
    /// 배경이 번지지 않는 `.modal` 을 쓴다.
    private var retryButton: some View {
        ButtonLarge("다시 연습하기", .modal) { send(.userTappedRetry) }
    }

    // MARK: - 보조

    private func statusMessage(
        _ message: String,
        showsProgress: Bool = false,
        showsRetry: Bool = false
    ) -> some View {
        VStack(spacing: .ds(.p12)) {
            Spacer()
            if showsProgress {
                ProgressView()
                    .tint(Color.HilitGreen.g500)
            }
            Text(message)
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g300)
                .multilineTextAlignment(.center)
            if showsRetry {
                // 문구는 클라 소유(§13 카피 미확정) — 확정되면 여기만 바꾼다.
                Button("다시 시도하기") { send(.userTappedReload) }
                    .buttonStyle(.mini(.black))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.ds(.p20))
    }

    private func message(for error: InterviewReportError) -> String {
        switch error {
        case .sessionNotFound: "리포트를 찾을 수 없어요."
        case .sessionExpired: "로그인이 만료됐어요.\n다시 로그인해 주세요."
        case .networkFailure: "네트워크 연결을 확인해 주세요."
        default: "리포트를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요."
        }
    }

    /// 재시도로 나아질 수 있는 에러만 버튼을 보여준다 (정의서 §4-4).
    /// 세션 없음(타인 소유·삭제)과 로그인 만료는 다시 눌러도 같은 답이다.
    private func isRetryable(_ error: InterviewReportError) -> Bool {
        switch error {
        case .sessionNotFound, .sessionExpired: false
        default: true
        }
    }

    /// 서버 `headline` 이 비었을 때의 폴백 (정의서 §6).
    static let headlineFallback = "이번 면접의 답변이 충분하지 않아요. 다음 면접 연습 때는 조금 더 충분한 답변을 말씀해주세요."
    /// 영상 카드 아래 안내 — 클라 소유 문구.
    static let videoExtensionNotice = "* 지인 1명이라도 피드백이 완료될 시 시청 시간이 최대로 연장됩니다."
}

#Preview("1차 리포트") {
    ReportMainView(
        store: Store(initialState: ReportMainFeature.State(sessionId: 1)) {
            ReportMainFeature()
        } withDependencies: {
            $0.interviewReportClient = .previewValue
        }
    )
}
