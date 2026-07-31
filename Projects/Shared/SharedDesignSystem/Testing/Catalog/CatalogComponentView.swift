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
            cameraGuideFrame
            choiceChip
            countdownCard
            dashIndicator
            feedbackCard
            fieldSubText
            fileCard
            fileUpload
            foldableCard
            highlightedText
            hilitCheckbox
            hilitDivider
            hilitNavigationBar
            hilitTextEditor
            hilitTextField
            hilitToggle
            homeModal
            infoField
            loadingModal
            loadingText
            messageCard
            modal
            nameField
            parallelogram
            quoteField
            reportCard
            saveIndicator
            tabSelector
            tagLabel
            titleBox
            videoControl
            videoOverlay
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
        CatalogGroup("DashIndicator — (count:current:) · 조각 폭은 균등 분할") {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                DashIndicator(count: 4, current: 1)
                DashIndicator(count: 5, current: 3)   // 시안 케이스 — 「5 step」 435:1575
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

    /// 시트 그대로 — padding 행(compact/regular) × 색조합 열. 행마다 있는 칸이 달라 `size.styles` 로 훑는다.
    private var tagLabel: some View {
        CatalogGroup("TagLabel — padding 행 × 색조합 열") {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                ForEach(TagLabel.Size.allCases, id: \.self) { size in
                    VStack(alignment: .leading, spacing: .ds(.p8)) {
                        Text(String(describing: size)).dsTypography(.body9)
                        HStack(spacing: .ds(.p8)) {
                            ForEach(size.styles, id: \.self) { style in
                                TagLabel("텍스트", style: style, size: size)
                            }
                        }
                    }
                }
            }
        }
    }
}

// 본체가 type_body_length(250줄) 를 넘어 데모를 extension 으로 나눠 뺐다.
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

// 네비바 데모 — 시스템 바를 그리려면 미니 NavigationStack 이 필요해 헬퍼와 같이 묶었다.
private extension CatalogComponentView {
    var hilitNavigationBar: some View {
        CatalogGroup("HilitNavigationBar — push=시스템 바 / present=수동 바. leading .close/.back/.hidden · 다크 · logo") {
            // 시스템 네비바는 NavigationStack 이 그린다 — 카탈로그에선 변형마다 미니 스택으로 시연.
            VStack(spacing: 0) {
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", trailing: .plus {}, background: .filled, onClose: {})
                }
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", trailing: .text("버튼") {}, background: .filled, onClose: {})
                }
                // leading — 뒤로가기 화살표.
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", trailing: .plus {}, background: .filled, leading: .back, onClose: {})
                }
                // leading 미노출 — 아이콘만 사라지고 슬롯 폭은 남는다(439:10396 / 439:10399).
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", trailing: .plus {}, background: .filled, leading: .hidden)
                }
                navigationBarDemo {
                    Color.clear.hilitNavigationBar("타이틀", surface: .dark, background: .filled, onClose: {})
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

    /// 네비바 44pt 만 보이게 잘라낸 미니 NavigationStack.
    func navigationBarDemo(@ViewBuilder content: () -> some View) -> some View {
        NavigationStack { content() }
            .frame(height: 44)
    }
}

// 카드·모달 계열 — 폭을 스스로 고정하지 않는 것들이라 페이지 콘텐츠 폭(375 − 좌우 20 = 335)에 그대로 눕는다.
private extension CatalogComponentView {
    /// 페이지가 주는 좌우 여백 — 판 안에 여백을 가진 풀블리드 줄은 이만큼 되돌린다.
    private static let pageInset: CGFloat = .ds(.p20)

    private static let foldableRows: [FoldableCardDetail.Row] = [
        .init("직군 · 연차", "{직군명} · {n}년"),
        .init("포트폴리오", "{파일명}.pdf"),
        .init("JD", "{Link}")
    ]

    var feedbackCard: some View {
        CatalogGroup("FeedbackCard — max / quote nil(서술형 미평가)") {
            VStack(spacing: .ds(.p12)) {
                FeedbackCard(
                    "평가 항목",
                    evaluation: "텍스트(이)라고 평가했어요",
                    highlight: "텍스트",
                    quote: "코멘트란입니다 코멘트란입니다",
                    onEdit: {}
                )
                FeedbackCard("평가 항목", evaluation: "텍스트(이)라고 평가했어요", highlight: "텍스트", onEdit: {})
            }
        }
    }

    var fileCard: some View {
        CatalogGroup("FileCard — max(accessory·x·툴팁) / tone .white / 파일명만") {
            VStack(spacing: .ds(.p12)) {
                FileCard(
                    "{파일명}.pdf",
                    date: "{20xx.xx.xx}",
                    size: "{0}mb",
                    note: "서브 텍스트",
                    showsTooltip: true,
                    onRemove: {}
                ) {
                    Button {} label: {
                        HStack(spacing: .ds(.p8)) {
                            Image.Video.default16
                            Text("버튼")
                        }
                    }
                    .buttonStyle(.mini(.gray, layout: .withIcon))
                }
                FileCard("{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb", tone: .white, onRemove: {})
                FileCard("{파일명}.pdf")
            }
        }
    }

    var fileUpload: some View {
        CatalogGroup("FileUpload — status 4종(before / empty / progressing / completed)") {
            VStack(spacing: .ds(.p12)) {
                FileUpload(.before(title: "파일을 업로드해주세요", guidance: "1개 파일, 최대 20Mb까지 가능합니다"))
                FileUpload(.empty(message: "아직 첨부된 포트폴리오가 없어요"))
                FileUpload(
                    .progressing(.init(name: "{파일명}.pdf", statusText: "Processing...", actionTitle: "버튼"), progress: 0.16),
                    onCancel: {},
                    onAction: {}
                )
                FileUpload(
                    .completed(.init(name: "{파일명}.pdf", statusText: "Completed!", actionTitle: "버튼")),
                    onCancel: {},
                    onAction: {}
                )
            }
        }
    }

    var foldableCard: some View {
        CatalogGroup("FoldableCard(+Detail) — 접힘 / 태그 2종 / 펼친 한 장(둘을 간격 0 으로 붙인다)") {
            VStack(spacing: .ds(.p12)) {
                FoldableCard("직군명 · n년차 면접", date: "{20xx.xx.xx}", time: "{xx:xx}")
                FoldableCard(
                    "직군명 · n년차 면접",
                    date: "{20xx.xx.xx}",
                    time: "{xx:xx}",
                    note: "삭제된 포트폴리오",
                    error: "생성 실패"
                )
                VStack(spacing: 0) {
                    FoldableCard("직군명 · n년차 면접", date: "{20xx.xx.xx}", time: "{xx:xx}", isExpanded: true)
                    FoldableCardDetail(
                        Self.foldableRows,
                        leadingAction: .init("레포트 보기") {},
                        trailingAction: .init("지인 피드백 받기") {},
                        error: "오류 문구를 노출해주세요"
                    )
                }
            }
        }
    }

    var homeModal: some View {
        CatalogGroup("HomeModal — opp(일러스트 + info) / port(content 슬롯에 FileCard)") {
            VStack(spacing: .ds(.p20)) {
                HomeModal(
                    "title",
                    subTitle: "sub-title",
                    icon: Image.Img.oppO,
                    info: "텍스트를 입력해주세요"
                )
                HomeModal("등록한 포트폴리오") {
                    FileCard("{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb")
                }
            }
            .padding(.ds(.p16))
            .background(Color.HilitBlack.b900.opacity(0.5))   // 실제 딤은 .hilitModal 오버레이 몫
        }
    }

    var loadingModal: some View {
        CatalogGroup("LoadingModal — 170 정사각 판 + 74 스피너(회전은 코드가 준다)") {
            LoadingModal()
                .padding(.ds(.p16))
                .frame(maxWidth: .infinity)
                .background(Color.HilitBlack.b900.opacity(0.5))
        }
    }

    var reportCard: some View {
        CatalogGroup("ReportCard — .open(b800) / .close(그린 띠). 여백이 판 안이라 화면 폭을 다 쓴다") {
            VStack(spacing: .ds(.p12)) {
                ReportCard(date: "0월 0일 월", status: .open(title: "title"))
                ReportCard(date: "0월 0일 월", status: .close)
            }
            .padding(.horizontal, -Self.pageInset)
        }
    }
}

// 판 색을 컴포넌트가 갖지 않는(또는 어두운 판 전제인) 것들 — 카탈로그가 판을 대신 깔아준다.
private extension CatalogComponentView {
    /// 시안 높이(523·229·76)는 카탈로그 한 페이지에 너무 길어 스크림 높이를 이 값으로 줄여 얹는다.
    private static let overlayHeight: CGFloat = 96

    private static let loadingPhrases: [String] = [
        "첫 번째 로딩 문구예요",
        "두 번째 로딩 문구",
        "세 번째 로딩 문구입니다"
    ]

    var cameraGuideFrame: some View {
        CatalogGroup("CameraGuideFrame — 327 정방형 · text 유무(blendsColorBurn 은 기본 off)") {
            VStack(spacing: .ds(.p12)) {
                CameraGuideFrame(text: "텍스트를 입력해주세요")
                CameraGuideFrame()
            }
            .frame(maxWidth: .infinity)
            .background(Color.GrayScale.g900)
        }
    }

    var hilitDivider: some View {
        CatalogGroup("HilitDivider — g800 1pt · 다크 판 전제") {
            VStack(spacing: .ds(.p12)) {
                HilitDivider()
                Text("두 줄 사이")
                    .dsTypography(.body6)
                    .foregroundStyle(Color.BlackWhite.white)
                HilitDivider()
            }
            .padding(.ds(.p16))
            .frame(maxWidth: .infinity)
            .background(Color.HilitBlack.b900)
        }
    }

    var loadingText: some View {
        CatalogGroup("LoadingText — .rolling / .settled(샤이닝). 활성 문구가 컨테이너 중앙") {
            VStack(spacing: .ds(.p16)) {
                LoadingText(Self.loadingPhrases, activeIndex: 1)
                LoadingText(Self.loadingPhrases, activeIndex: 2, phase: .settled)
            }
            .padding(.vertical, .ds(.p16))
            .frame(maxWidth: .infinity)
            .background(Color.GrayScale.g800)
        }
    }

    var messageCard: some View {
        CatalogGroup("MessageCard — .detail(b800 판 · 줄 유무) / .mini(g800 판)") {
            VStack(spacing: .ds(.p12)) {
                MessageCard(.detail(subtitle: "sub-title", title: "title", contents: "contents"))
                MessageCard(
                    .detail(subtitle: nil, title: "타이틀만 있는 경우", contents: "본문은 남는다"),
                    icon: Image.HilitAnalyze.success
                )
                MessageCard(.mini("contents"))
            }
        }
    }

    var videoControl: some View {
        CatalogGroup("VideoControl — isPlaying true(⏸ 글리프) / false(▷)") {
            VStack(spacing: .ds(.p20)) {
                VideoControl(isPlaying: true, onSkipBackward: {}, onPlayPauseToggle: {}, onSkipForward: {})
                VideoControl(isPlaying: false, onSkipBackward: {}, onPlayPauseToggle: {}, onSkipForward: {})
            }
            .padding(.ds(.p16))
            .frame(maxWidth: .infinity)
            .background(Color.HilitBlack.b900)
        }
    }

    var videoOverlay: some View {
        CatalogGroup("VideoOverlay — 실재하는 3조합. 높이는 카탈로그용으로 줄였다(램프 비율은 유지)") {
            VStack(spacing: .ds(.p12)) {
                ForEach(VideoOverlay.Variant.allCases, id: \.self) { variant in
                    ZStack(alignment: .bottom) {
                        Color.GrayScale.g600
                        VideoOverlay(variant, height: Self.overlayHeight)
                    }
                    .frame(height: Self.overlayHeight)
                    .overlay(alignment: .topLeading) {
                        Text(String(describing: variant))
                            .dsTypography(.body9)
                            .foregroundStyle(Color.BlackWhite.white)
                            .padding(.ds(.p4))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CatalogComponentView() }
}
