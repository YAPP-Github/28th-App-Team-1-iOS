//
//  FeedbackCard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «feedback-card» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=2101-8861
// 케이스(Component System 3, 439:10241): 439:10351 max(335×89) · 439:10352 서술형 미평가(335×67)

import SwiftUI

/// 지인 피드백 한 장 — Figma «feedback-card» 1:1.
///
/// 흰 판 + **비대칭 테두리**(왼쪽 6 `outline-mega`, 나머지 세 변 1.2 `outline-m`, 전부 g100) ·
/// px16 py12 · 세로 간격 6: «평가 항목 라벨 / 마커 얹힌 평가 문장 / 인용 코멘트 / 수정 아이콘».
///
/// ```swift
/// FeedbackCard(
///     "평가 항목",
///     evaluation: "텍스트(이)라고 평가했어요",
///     highlight: "텍스트",
///     quote: "코멘트란입니다",
///     onEdit: { … }
/// )
///
/// FeedbackCard("평가 항목", evaluation: "텍스트(이)라고 평가했어요", highlight: "텍스트")  // 서술형 미평가
/// ```
///
/// Figma 의 «서술형 미평가» 케이스는 `quote` nil — 인용 줄만 빠지고 나머지는 그대로다.
/// 평가 문장은 `HighlightedText` 의 blue 조합(p200 판 + p800 글자)이고 평문은 b800 이다 —
/// **문장 전체를 넘기고 `highlight` 로 마커 구간만 지정한다**(그 컴포넌트 계약).
/// 인용 줄은 `QuoteField(.gray)` 를 그대로 쓴다 — 그 안의 타이포 불일치는 그쪽 독스트링에 기록돼 있다.
///
/// 시안 backdrop blur 10 은 미반영이다 — 판이 불투명 흰색이라 뒤가 보이지 않아 차이가 없다
/// (`.hilitModal` 의 blur 40 과 같은 판단). 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을
/// 뺀 값이라 호출부 레이아웃 몫이다.
public struct FeedbackCard: View {
    private let item: String
    private let evaluation: String
    private let highlight: String
    private let quote: String?
    private let onEdit: (() -> Void)?

    /// - Parameters:
    ///   - item: 맨 위 «평가 항목» 라벨.
    ///   - evaluation: 평가 문장 **전체** (마커 구간을 포함한 한 문장).
    ///   - highlight: `evaluation` 안에서 마커를 칠할 부분 문자열.
    ///   - quote: 남긴 코멘트. nil 이면 인용 줄을 그리지 않는다 (Figma «서술형 미평가»).
    ///   - onEdit: 오른쪽 수정 아이콘(`edit/16px/disabled`) 동작. nil 이면 아이콘을 그리지 않는다.
    public init(
        _ item: String,
        evaluation: String,
        highlight: String,
        quote: String? = nil,
        onEdit: (() -> Void)? = nil
    ) {
        self.item = item
        self.evaluation = evaluation
        self.highlight = highlight
        self.quote = quote
        self.onEdit = onEdit
    }

    public var body: some View {
        HStack(alignment: .top, spacing: .ds(.p8)) {
            VStack(alignment: .leading, spacing: Metric.rowSpacing) {
                Text(item)
                    .dsTypography(.body9)
                    .foregroundStyle(Color.GrayScale.g400)
                HighlightedText(evaluation, typography: .body2, plainForeground: Color.HilitBlack.b800)
                    .hilight(highlight)
                    .hilightColor(.blue)
                if let quote {
                    QuoteField(quote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let onEdit {
                Button(action: onEdit) {
                    Image.Edit.disabled16
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metric.iconSide, height: Metric.iconSide)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .ds(.p16))
        .padding(.vertical, .ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.BlackWhite.white)
        // 세 변 1.2 → 그 위에 왼쪽 6 을 덮는다. 모서리 0 — 캡슐이 아니다.
        .overlay {
            Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.medium))
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.GrayScale.g100)
                .frame(width: .ds(.mega))
        }
    }

    private enum Metric {
        /// 수정 아이콘 한 변 16 — Figma `edit/16px`.
        static let iconSide: CGFloat = 16
        /// 세 줄 사이 간격. Figma raw 6 — spacing 스케일이 4 다음 8 이라 토큰화 보류
        /// (`QuoteField.Metric.gap` 과 같은 값·같은 이유).
        static let rowSpacing: CGFloat = 6
    }
}

// MARK: - Previews

/// 시안 프레임 335 = 화면 375 − 좌우 20. 실사용 폭은 호출부가 정한다.
private let previewFeedbackCardWidth: CGFloat = 335

#Preview("max case — 439:10351") {
    FeedbackCard(
        "평가 항목",
        evaluation: "텍스트(이)라고 평가했어요",
        highlight: "텍스트",
        quote: "코멘트란입니다 코멘트란입니다 코멘트란입니다",
        onEdit: {}
    )
    .frame(width: previewFeedbackCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("서술형 미평가 — 439:10352") {
    FeedbackCard(
        "평가 항목",
        evaluation: "텍스트(이)라고 평가했어요",
        highlight: "텍스트",
        onEdit: {}
    )
    .frame(width: previewFeedbackCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("수정 아이콘 없음 · 긴 문장·긴 코멘트") {
    VStack(spacing: .ds(.p20)) {
        FeedbackCard("평가 항목", evaluation: "텍스트(이)라고 평가했어요", highlight: "텍스트")
        FeedbackCard(
            "면접 태도",
            evaluation: "목소리가 안정적이고 자신감 있었어요(이)라고 평가했어요",
            highlight: "목소리가 안정적",
            quote: "아주 긴 코멘트라서 한 줄에 들어가지 않고 말줄임으로 잘려야 하는 경우를 확인한다",
            onEdit: {}
        )
    }
    .frame(width: previewFeedbackCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}
