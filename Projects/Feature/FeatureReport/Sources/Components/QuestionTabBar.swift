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
/// 칩 생김새는 `DarkChip`(16pt — DS `.mini` 미커버 티어)이 갖는다.
struct QuestionTabBar: View {
    let cards: [InterviewReportCard]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .ds(.p10)) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    DarkChip(title: card.displayTitle, isSelected: index == selectedIndex) {
                        onSelect(index)
                    }
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
