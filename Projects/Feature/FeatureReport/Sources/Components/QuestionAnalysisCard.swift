//
//  QuestionAnalysisCard.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 질문 의도 분석 카드 — 그림은 DS `MessageCard`(Figma «message-card» 435:1392, size=detail)가 그리고,
/// 이 타입은 «Hilit의 질문 분석» 라벨 + 반짝임 아이콘만 소유한다.
///
/// **메인에 서는 분석 카드는 질문 분석 한 종류뿐이다** (시안 443:7204) —
/// «Hilit의 답변 분석» 은 하이라이트 상세 시트 전용이라 `ReportHighlightDetailView` 가 직접 그린다.
/// 해상도·레드플래그 «안내» 는 분석이 아니라서 카드 본문에 서지 않고 «상세 리포트» 제목 옆 느낌표 툴팁으로 간다.
///
/// 라벨이 종류에서 결정되는 도메인 문구라서 DS 로 승격하지 않는다 —
/// DS 는 문구를 모르는 채 `subtitle`/`title`/`contents` 세 줄만 받는다.
struct QuestionAnalysisCard: View {
    /// 볼드 한 줄 = 서버 `card.questionIntentTitle`. nil 이면 카드가 그 줄만 빼고 그린다.
    var title: String?
    /// 분석 본문 (서버 소유 문구).
    let contents: String

    var body: some View {
        MessageCard(
            .detail(subtitle: Self.label, title: title, contents: contents),
            icon: Image.HilitAnalyze.question
        )
    }

    /// 카드 라벨 — 클라 소유 고정 문구. 호출부가 넘기지 않는다.
    private static let label = "Hilit의 질문 분석"
}

#Preview("질문 분석 카드") {
    VStack(spacing: .ds(.p16)) {
        QuestionAnalysisCard(
            title: "트래픽 확장 대응 전략",
            contents: "트래픽이 증가했을 때 발생할 병목 지점과 시스템의 한계, 그리고 이를 어떻게 판단할지 설명하는 질문입니다."
        )
        // 서버 `questionIntentTitle` 이 비어 볼드 줄만 빠진 경우.
        QuestionAnalysisCard(
            contents: "성능 문제를 얼마나 구체적으로 인지했는지 확인하는 질문입니다."
        )
        // 같은 카드 안에 함께 서는 «안내» 한 줄 — 분석 카드가 아니다.
        MessageCard(.mini("영상 해상도가 낮아 분석율이 떨어질 수 있어요."))
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
