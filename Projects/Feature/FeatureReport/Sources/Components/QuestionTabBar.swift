//
//  QuestionTabBar.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

/// 상세 리포트의 질문 선택 탭. 카드가 5개를 넘으면 가로 스크롤한다(Figma 는 5개 기준 폭을 이미 넘긴다).
///
/// 칩은 DS `.mini` 다크 판 그대로다 — 선택 green(g500 판 + g800 라벨) / 미선택 gray(g900 + g300).
/// 시안이 이 인스턴스만 16pt 로 그려서(443:7284) `typography:` 로 덮는다:
/// 선택은 body2(16 SemiBold), 미선택은 한 단계 가벼운 body3(16 Medium).
struct QuestionTabBar: View {
    let cards: [InterviewReportCard]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .ds(.p10)) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    let isSelected = index == selectedIndex
                    Button(card.displayTitle) { onSelect(index) }
                        .buttonStyle(
                            .mini(
                                isSelected ? .green : .gray,
                                typography: isSelected ? .body2 : .body3
                            )
                        )
                }
            }
        }
    }
}

#Preview("질문 탭") {
    QuestionTabBar(
        cards: (1...5).map { index in
            InterviewReportCard(
                axisOrder: index,
                depthLevel: 1,
                questionText: nil,
                transcript: nil,
                highlightSpans: nil,
                resolutionNotice: nil,
                cardRedFlagNotices: nil,
                questionIntent: nil
            )
        },
        selectedIndex: 0,
        onSelect: { _ in }
    )
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
