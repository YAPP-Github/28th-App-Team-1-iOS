//
//  FileCard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «card» (card-pdf) https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=439-10334
// 케이스 매트릭스(Component System 3, 439:10241) — 아홉 인스턴스 전부 335×69:
// 439:10334 max · 439:10335 x 버튼만 존재 · 439:10336 서브텍스트만 노출 · 439:10337 파일 컬러 변경 ·
// 439:10338 버튼 미니가 존재 · 439:10339 날짜·용량만 노출 · 439:10340 only 파일명 ·
// 439:10341 버튼 미존재 · 439:10342 툴팁 미노출

import SwiftUI

/// 첨부 파일 한 줄 카드 — Figma «card»(card-pdf) 1:1.
///
/// 흰 판 + g100 1.5(`outline-sb`) 사방 테두리 · p14 · 가로 간격 12:
/// «36pt 파일 아이콘 / 파일명 + 메타 줄 / 삭제 x / 버튼 슬롯».
///
/// ```swift
/// FileCard("포트폴리오.pdf", date: "2026.07.31", size: "2mb", onRemove: { … })
///
/// FileCard("포트폴리오.pdf", note: "분석 중", showsTooltip: true) {
///     Button { … } label: {
///         HStack(spacing: .ds(.p8)) { Image.Video.default16; Text("영상 다시보기") }
///     }
///     .buttonStyle(.mini(.gray, layout: .withIcon))
/// }
/// ```
///
/// Figma 의 «x 버튼만 / 버튼 미니가 존재 / 버튼 미존재 / 날짜·용량만 / 서브텍스트만 / only 파일명 /
/// 툴팁 미노출» 축은 전부 **값의 유무**로 표현한다 — 슬롯·클로저가 nil 이면 그 자리가 사라진다.
/// 오른쪽 버튼은 열린 슬롯이다(카드마다 라벨·아이콘이 다르다). 시안은 `button-mini` 회색 with-icon 판이라
/// `.mini(.gray, layout: .withIcon)` 을 넣는다 — 배색·눌림은 그쪽 몫.
///
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
/// `HomeModal` 의 `property1=port` 케이스가 `content` 슬롯에 얹는 카드가 이것이다.
public struct FileCard<Accessory: View>: View {
    /// 파일 아이콘 색 — Figma `file/36px/{green,white}` (439:10337 «파일 컬러 변경»).
    /// b800 타일에 구워진 두 벌짜리 에셋이라 틴트가 아니라 에셋 교체다.
    public enum Tone: Sendable, CaseIterable {
        /// 그린 글리프 (기본)
        case green
        /// 흰 글리프
        case white
    }

    private let name: String
    private let date: String?
    private let size: String?
    private let note: String?
    private let showsTooltip: Bool
    private let tone: Tone
    private let onRemove: (() -> Void)?
    private let accessory: Accessory

    /// - Parameters:
    ///   - name: 파일명. 한 줄로 잘리고 넘치면 말줄임.
    ///   - date: 등록일. `size` 와 함께 있으면 사이에 세로 구분선이 들어간다. nil 이면 숨김.
    ///   - size: 용량 표기. 형식(`2mb`)은 호출부가 만든다. nil 이면 숨김.
    ///   - note: 메타 줄 오른쪽 서브 텍스트. nil 이면 숨김.
    ///   - showsTooltip: 서브 텍스트 뒤 안내 아이콘(`info/16px/disabled`). **아이콘만 그린다** —
    ///     실제 툴팁 표출은 호출부 몫이다.
    ///   - tone: 파일 아이콘 색 (Figma `file/36px` 변형).
    ///   - onRemove: 삭제 x(`cancel mini/16px/gray`) 동작. nil 이면 x 를 그리지 않는다.
    ///   - accessory: 오른쪽 버튼 자리 — `.mini(…)` 버튼. 기본 없음.
    public init(
        _ name: String,
        date: String? = nil,
        size: String? = nil,
        note: String? = nil,
        showsTooltip: Bool = false,
        tone: Tone = .green,
        onRemove: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.name = name
        self.date = date
        self.size = size
        self.note = note
        self.showsTooltip = showsTooltip
        self.tone = tone
        self.onRemove = onRemove
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: .ds(.p12)) {
            fileIcon
                .resizable()
                .scaledToFit()
                .frame(width: Metric.fileSide, height: Metric.fileSide)
            // 파일명·메타는 위쪽 정렬 — 시안의 x 는 두 줄 블록의 첫 줄에 붙는다.
            HStack(alignment: .top, spacing: .ds(.p8)) {
                textColumn
                if let onRemove {
                    Button(action: onRemove) {
                        Image.CancelMini.gray16
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metric.iconSide, height: Metric.iconSide)
                    }
                    .buttonStyle(.plain)
                }
            }
            accessory
        }
        .padding(.ds(.p14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.BlackWhite.white)
        .overlay {
            // 모서리 0 — 캡슐이 아니다.
            Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.semiBold))
        }
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: .ds(.p4)) {
            Text(name)
                .lineLimit(1)
                .truncationMode(.tail)
                .dsTypography(.body2)
                .foregroundStyle(Color.GrayScale.g700)
                .frame(maxWidth: .infinity, alignment: .leading)
            if hasMeta {
                metaRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// «날짜 | 용량» 묶음 + «서브 텍스트 + 안내 아이콘» 묶음. 두 묶음 사이 간격 4.
    private var metaRow: some View {
        HStack(spacing: .ds(.p4)) {
            if date != nil || size != nil {
                HStack(spacing: .ds(.p4)) {
                    if let date {
                        metaText(date)
                    }
                    if date != nil, size != nil {
                        Rectangle()
                            .fill(Color.GrayScale.g200)
                            .frame(width: .ds(.medium), height: Metric.dividerHeight)
                    }
                    if let size {
                        metaText(size)
                    }
                }
            }
            if note != nil || showsTooltip {
                HStack(spacing: Metric.noteSpacing) {
                    if let note {
                        // 서브 텍스트만 m12(`body9`) 다 — 날짜·용량은 r12(`body10`).
                        Text(note)
                            .dsTypography(.body9)
                            .foregroundStyle(Color.GrayScale.g400)
                    }
                    if showsTooltip {
                        Image.Info.disabled
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metric.iconSide, height: Metric.iconSide)
                    }
                }
            }
        }
    }

    private func metaText(_ value: String) -> some View {
        Text(value)
            .dsTypography(.body10)
            .foregroundStyle(Color.GrayScale.g400)
    }

    private var hasMeta: Bool {
        date != nil || size != nil || note != nil || showsTooltip
    }

    private var fileIcon: Image {
        switch tone {
        case .green: Image.File.green36
        case .white: Image.File.white36
        }
    }

    private enum Metric {
        /// 파일 아이콘 한 변 36 — Figma `file/36px`.
        static let fileSide: CGFloat = 36
        /// x·안내 아이콘 한 변 16 — Figma `cancel mini/16px` · `info/16px`.
        static let iconSide: CGFloat = 16
        /// 날짜–용량 구분선 높이 10. 두께는 `outline-m`(시안 stroke 1.2).
        static let dividerHeight: CGFloat = 10
        /// 서브 텍스트–안내 아이콘 간격. Figma raw 6 — spacing 스케일이 4 다음 8 이라 토큰화 보류.
        static let noteSpacing: CGFloat = 6
    }
}

public extension FileCard where Accessory == EmptyView {
    /// 오른쪽 버튼 없는 파일 카드 (Figma «버튼 미존재» 439:10341).
    init(
        _ name: String,
        date: String? = nil,
        size: String? = nil,
        note: String? = nil,
        showsTooltip: Bool = false,
        tone: Tone = .green,
        onRemove: (() -> Void)? = nil
    ) {
        self.init(
            name,
            date: date,
            size: size,
            note: note,
            showsTooltip: showsTooltip,
            tone: tone,
            onRemove: onRemove
        ) { EmptyView() }
    }
}

// MARK: - Figma 원본 불일치
//
// 「only 파일명」(439:10340) 인스턴스도 높이가 69 로 나온다 — 파일명만 남으면 아이콘 36 + p14×2 = 64 여야
// 하는데, 내용을 다 숨긴 메타 줄 프레임이 16pt 를 그대로 붙들고 있어서다(auto-layout 빈 프레임 잔재).
// 코드는 그 줄을 접는다(64pt). 리스트에서 행 높이를 맞춰야 하면 호출부가 `.frame(height:)` 로 정한다.

// MARK: - Previews

/// 시안 프레임 335 = 화면 375 − 좌우 20. 실사용 폭은 호출부가 정한다.
private let previewFileCardWidth: CGFloat = 335

/// 시안 `button-mini` 회색 with-icon 판 — 카드 오른쪽 슬롯에 들어가는 조합.
private var previewMiniButton: some View {
    Button {} label: {
        HStack(spacing: .ds(.p8)) {
            Image.Video.default16
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("버튼")
        }
    }
    .buttonStyle(.mini(.gray, layout: .withIcon))
}

#Preview("버튼·x 축 — 439:10334 · 10335 · 10338 · 10341") {
    VStack(spacing: .ds(.p20)) {
        // max case — 439:10334
        FileCard(
            "{파일명}.pdf",
            date: "{20xx.xx.xx}",
            size: "{0}mb",
            note: "서브 텍스트",
            showsTooltip: true,
            onRemove: {}
        ) {
            previewMiniButton
        }
        // x 버튼만 존재 — 439:10335
        FileCard(
            "{파일명}.pdf",
            date: "{20xx.xx.xx}",
            size: "{0}mb",
            note: "서브 텍스트",
            showsTooltip: true,
            onRemove: {}
        )
        // 버튼 미니가 존재 — 439:10338
        FileCard(
            "{파일명}.pdf",
            date: "{20xx.xx.xx}",
            size: "{0}mb",
            note: "서브 텍스트",
            showsTooltip: true
        ) {
            previewMiniButton
        }
        // 버튼 미존재 — 439:10341
        FileCard(
            "{파일명}.pdf",
            date: "{20xx.xx.xx}",
            size: "{0}mb",
            note: "서브 텍스트",
            showsTooltip: true
        )
    }
    .frame(width: previewFileCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("메타 축 — 439:10336 · 10339 · 10340 · 10342") {
    VStack(spacing: .ds(.p20)) {
        // 서브텍스트만 노출 — 439:10336
        FileCard("{파일명}.pdf", note: "서브 텍스트", onRemove: {})
        // 날짜·용량만 노출 — 439:10339
        FileCard("{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb", onRemove: {})
        // only 파일명 — 439:10340
        FileCard("{파일명}.pdf")
        // 툴팁 미노출 — 439:10342
        FileCard(
            "{파일명}.pdf",
            date: "{20xx.xx.xx}",
            size: "{0}mb",
            note: "서브 텍스트",
            onRemove: {}
        )
    }
    .frame(width: previewFileCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("파일 컬러 변경 — 439:10337") {
    VStack(spacing: .ds(.p20)) {
        FileCard("{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb", tone: .green, onRemove: {})
        FileCard("{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb", tone: .white, onRemove: {})
    }
    .frame(width: previewFileCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("긴 파일명 — 말줄임") {
    FileCard(
        "아주 길어서 한 줄에 들어가지 않는 포트폴리오 파일 이름입니다 정말 깁니다.pdf",
        date: "{20xx.xx.xx}",
        size: "{0}mb",
        onRemove: {}
    ) {
        previewMiniButton
    }
    .frame(width: previewFileCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}
