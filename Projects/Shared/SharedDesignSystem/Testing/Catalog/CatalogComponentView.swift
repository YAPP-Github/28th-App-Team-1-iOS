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
    @State private var editorText: String = ""
    @State private var fieldText: String = ""
    @State private var isChecked: Bool = true
    @State private var isToggleOn: Bool = true
    @State private var name: String = "김은서"
    @State private var tab: SampleTab = .first

    var body: some View {
        CatalogPage("컴포넌트") {
            bubbleField
            choiceChip
            countdownCard
            dashIndicator
            fieldSubText
            highlightedText
            hilitCheckbox
            hilitNavigationBar
            hilitTextEditor
            hilitTextField
            hilitToggle
            infoField
            modal
            nameField
            parallelogram
            quoteField
            saveIndicator
            tabSelector
            tagLabel
            titleBox
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

    private var countdownCard: some View {
        CatalogGroup("CountdownCard — .active / .ended") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                CountdownCard(title: "title", subtitle: "sub-title", time: "00:00:00")
                CountdownCard(title: "title", subtitle: "sub-title", time: "00:00:00", status: .ended)
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

    private var hilitCheckbox: some View {
        CatalogGroup("HilitCheckboxStyle — Toggle(isOn:).toggleStyle(.hilitCheckbox)") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                Toggle(isOn: $isChecked) { EmptyView() }
                Toggle(isOn: .constant(false)) { EmptyView() }
                Toggle(isOn: .constant(true)) { Text("라벨 동반").dsTypography(.body6) }
            }
            .toggleStyle(.hilitCheckbox)
        }
    }

    private var hilitNavigationBar: some View {
        CatalogGroup("HilitNavigationBar — push=시스템 바 / present=수동 바. 표준(X 고정) / 다크 / logo") {
            // 시스템 내비바는 NavigationStack 이 그린다 — 카탈로그에선 변형마다 미니 스택으로 시연.
            VStack(spacing: 0) {
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", trailing: .plus {}, background: .filled, onClose: {})
                }
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", trailing: .text("버튼") {}, background: .filled, onClose: {})
                }
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", theme: .dark, background: .filled, onClose: {})
                }
                navigationBarDemo {
                    Color.clear.hilitLogoNavigationBar(background: .filled, onProfile: {})
                }
                // present 화면용 수동 바 — 스택 불필요, 좌우 여백만 시안값(px20)이라 위와 수 pt 다름.
                Color.clear.frame(height: 0)
                    .hilitPresentedNavigationBar("타이틀 (presented)", trailing: .plus {}, background: .filled, onClose: {})
            }
        }
    }

    /// 내비바 44pt 만 보이게 잘라낸 미니 NavigationStack.
    private func navigationBarDemo(@ViewBuilder content: () -> some View) -> some View {
        NavigationStack { content() }
            .frame(height: 44)
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

    private var infoField: some View {
        CatalogGroup("InfoField — .gray / .error") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                InfoField("텍스트를 입력해주세요")
                InfoField("텍스트를 입력해주세요", style: .error)
            }
        }
    }

    private var modal: some View {
        CatalogGroup("Modal — icon·subText·info 는 nil 로 숨김, 버튼은 슬롯") {
            VStack(spacing: .ds(.p20)) {
                Modal(
                    "텍스트를 입력해주세요",
                    subText: "서브텍스트를 입력해주세요",
                    icon: Image.Img.book,
                    info: "텍스트를 입력해주세요"
                ) {
                    ButtonLarge("버튼1", .modal) {}
                }
                Modal("정말 나가시겠어요?") {
                    ButtonLarge(.modal, tone: .twoColor) {
                        Button("취소") {}
                    } trailing: {
                        Button("나가기") {}
                    }
                }
            }
        }
    }

    private var nameField: some View {
        CatalogGroup("NameField — status 는 입력값에서 파생(빈 값 / 입력됨)") {
            VStack(spacing: .ds(.p16)) {
                NameField("이름을 알려주세요", text: .constant(""))
                NameField("이름을 알려주세요", text: $name)
            }
            .frame(maxWidth: .infinity)
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

// 본체가 type_body_length(250줄) 를 넘어 입력 필드 3종 데모는 extension 으로 뺐다.
// 표시 순서는 body 목록이 정하므로 여기 위치는 무관 — 새 데모도 본체가 차면 여기로.
private extension CatalogComponentView {
    var fieldSubText: some View {
        CatalogGroup("FieldSubText — .info / .success / .error") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                FieldSubText("서브 텍스트를 입력해주세요")
                FieldSubText("서브 텍스트를 입력해주세요", status: .success)
                FieldSubText("서브 텍스트를 입력해주세요", status: .error)
            }
        }
    }

    var hilitTextEditor: some View {
        CatalogGroup("HilitTextEditor — 높이 158 고정 · maxLength 카운터") {
            HilitTextEditor("텍스트를 입력해주세요", text: $editorText, maxLength: 300)
        }
    }

    var hilitTextField: some View {
        CatalogGroup("HilitTextField — 포커스 파생 · status 4종 · subText · maxLength") {
            VStack(alignment: .leading, spacing: .ds(.p16)) {
                HilitTextField("텍스트를 입력해주세요", text: $fieldText, subText: "서브 텍스트를 입력해주세요")
                HilitTextField("텍스트를 입력해주세요", text: .constant(""), status: .loading("분석 중"))
                HilitTextField("텍스트를 입력해주세요", text: .constant("입력한 텍스트"), status: .success, subText: "서브 텍스트를 입력해주세요")
                HilitTextField("텍스트를 입력해주세요", text: .constant("입력한 텍스트"), status: .error, subText: "서브 텍스트를 입력해주세요")
                HilitTextField("텍스트를 입력해주세요", text: $fieldText, maxLength: 300)
            }
        }
    }

    private static let titleLines: [TitleBox.Line] = [
        .init("타이틀을 이렇게 적어주세요", highlight: "이렇게"),
        .init("두 번째 줄은 이렇게 입력해주세요", highlight: "이렇게")
    ]

    var titleBox: some View {
        CatalogGroup("TitleBox — alignment(.leading/.center) · 판은 .hilitSurface(_:)") {
            VStack(spacing: .ds(.p20)) {
                TitleBox(Self.titleLines, tag: "필수", sub: "서브 타이틀을 입력해주세요")
                TitleBox(Self.titleLines, sub: "서브 타이틀을 입력해주세요", alignment: .center)
                TitleBox(Self.titleLines, tag: "필수", sub: "서브 타이틀을 입력해주세요")
                    .padding(.ds(.p16))
                    .background(Color.HilitBlack.b900)   // 흰 글자라 어두운 판에서만 보인다
                    .hilitSurface(.dark)
            }
        }
    }
}

#Preview {
    NavigationStack { CatalogComponentView() }
}
