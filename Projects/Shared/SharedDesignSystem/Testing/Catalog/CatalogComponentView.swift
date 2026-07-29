//
//  CatalogComponentView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 버튼 밖 공용 컴포넌트 전부 — 이름 알파벳순(문서 표와 같은 순서).
/// 상태를 갖는 것(ChoiceChip·Toggle·TabSelector)은 여기서 `@State` 를 대신 들어준다.
struct CatalogComponentView: View {
    private enum SampleTab: Hashable { case first, second, third }

    @State private var chipSelection: Bool = true
    @State private var isToggleOn: Bool = true
    @State private var tab: SampleTab = .first

    var body: some View {
        CatalogPage("컴포넌트") {
            bubbleField
            choiceChip
            dashIndicator
            highlightedText
            hilitToggle
            parallelogram
            quoteField
            saveIndicator
            tabSelector
            tagLabel
        }
    }

    private var bubbleField: some View {
        CatalogGroup("BubbleField — .wide(tail:) 3종 · .mini(mood:) 2종") {
            VStack(alignment: .leading, spacing: .ds(.p16)) {
                BubbleField("모든 평가가 끝났어요!")
                BubbleField("꼬리가 좌상단이에요", .wide(tail: .top))
                BubbleField("꼬리가 우하단이에요", .wide(tail: .bottom))
                BubbleField("mini light", .mini(mood: .light))
                BubbleField("mini dark", .mini(mood: .dark))
            }
        }
    }

    private var choiceChip: some View {
        CatalogGroup("ChoiceChip — 선택 상태 → 톤") {
            HStack(spacing: .ds(.p8)) {
                ChoiceChip("아쉬웠어요", isSelected: !chipSelection, tone: .negative) { chipSelection = false }
                ChoiceChip("좋았어요", isSelected: chipSelection, tone: .positive) { chipSelection = true }
            }
        }
    }

    private var dashIndicator: some View {
        CatalogGroup("DashIndicator — (count:current:)") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                DashIndicator(count: 4, current: 1)
                DashIndicator(count: 4, current: 3)
                DashIndicator(count: 4, current: 4)
            }
        }
    }

    private var highlightedText: some View {
        CatalogGroup("HighlightedText — hilight 체인(색 6종 · fill 3종)") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                ForEach(HighlightedText.Tone.allCases, id: \.self) { tone in
                    HighlightedText("시선을 잘 마주쳤어요", typography: .sub4)
                        .hilight("시선")
                        .hilightColor(tone)
                }
                HighlightedText("띠가 글자 가운데를 지나요", typography: .sub4)
                    .hilight("가운데")
                    .hilightFill(.midlined)
                HighlightedText("띠가 글자 아래에 깔려요", typography: .sub4)
                    .hilight("아래")
                    .hilightFill(.underlined)
                HighlightedText("아이콘을 앞에 붙여요", typography: .sub4)
                    .hilight("아이콘")
                    .hilightIcon(Image.Ai.green24)
            }
        }
    }

    private var hilitToggle: some View {
        CatalogGroup("HilitToggleStyle — Toggle(isOn:).toggleStyle(.hilit)") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                Toggle(isOn: $isToggleOn) { EmptyView() }
                Toggle(isOn: .constant(false)) { EmptyView() }
                Toggle(isOn: .constant(true)) { Text("라벨 동반").dsTypography(.body6) }
            }
            .toggleStyle(.hilit)
        }
    }

    private var parallelogram: some View {
        CatalogGroup("Parallelogram — 하이라이트 배경 Shape(slant:)") {
            HStack(spacing: .ds(.p8)) {
                Parallelogram()
                    .fill(Color.HilitGreen.g500)
                    .frame(width: 120, height: 24)
                Parallelogram(slant: 10)
                    .fill(Color.Positive.p200)
                    .frame(width: 120, height: 24)
            }
        }
    }

    private var quoteField: some View {
        CatalogGroup("QuoteField — .gray / .greenOnDark / .block") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                QuoteField("코멘트란입니다 코멘트란입니다 코멘트란입니다")
                QuoteField("코멘트란입니다 코멘트란입니다", style: .greenOnDark)
                    .padding(.ds(.p8))
                    .background(Color.HilitBlack.b900)   // 흰 글자라 어두운 판에서만 보인다
                QuoteField("코멘트란입니다 코멘트란입니다", style: .block, onEdit: {})
            }
        }
    }

    private var saveIndicator: some View {
        CatalogGroup("SaveIndicator — .saving / .saved") {
            HStack(spacing: .ds(.p12)) {
                SaveIndicator(.saving)
                SaveIndicator(.saved)
            }
        }
    }

    private var tabSelector: some View {
        CatalogGroup("TabSelector — .hug / .fill · isEnabled: false") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                TabSelector(
                    [
                        .init(tag: SampleTab.first, title: "전체"),
                        .init(tag: SampleTab.second, title: "지인"),
                        .init(tag: SampleTab.third, title: "면접관", isEnabled: false)
                    ],
                    selection: $tab
                )
                TabSelector(
                    [
                        .init(tag: SampleTab.first, title: "전체"),
                        .init(tag: SampleTab.second, title: "지인"),
                        .init(tag: SampleTab.third, title: "면접관")
                    ],
                    selection: $tab,
                    layout: .fill
                )
            }
        }
    }

    private var tagLabel: some View {
        CatalogGroup("TagLabel — 기본 회색 · 척도 극 라벨") {
            HStack(spacing: .ds(.p8)) {
                TagLabel("선택")
                TagLabel("좋았어요", foreground: Color.Positive.p800, background: Color.Positive.p200)
                TagLabel("아쉬웠어요", foreground: Color.Error.e500, background: Color.Error.e200)
            }
        }
    }
}

#Preview {
    NavigationStack { CatalogComponentView() }
}
