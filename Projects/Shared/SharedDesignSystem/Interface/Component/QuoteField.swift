//
//  QuoteField.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

import SwiftUI

/// 작성된 코멘트를 인용 형태로 되보여주는 줄 — Figma «quote-field» 1984:7003 (`color` 축 3종).
///
/// **입력 위젯이 아니다.** 시안에 커서·placeholder·포커스 상태가 없고 `.block` 은 오른쪽 «수정» 링크로
/// 편집을 다른 화면(코멘트 입력 카드)에 넘긴다 — 그래서 안에 `TextField` 를 두지 않고, 타이핑이 필요하면
/// 호출부가 이 줄을 탭 소스로 쓰고 편집 UI 를 띄운다.
///
/// 세로 바가 «인용» 표식이고 판에 따라 색·굵기·글자 크기가 갈린다:
/// `.gray` 2pt 회색 바(1984:7002) · `.greenOnDark` 2pt 그린 바 + 흰 글자(1984:7001) ·
/// `.block` g50 판 + 4pt 그린 바 + 14pt 글자(2096:8190).
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct QuoteField: View {
    /// Figma `color` 축. 판(밝음/어둠)과 형태가 함께 묶여 있어 Environment(`hilitSurface`)로 풀지 않았다 —
    /// 시안에 «다크 판의 gray», «다크 판의 block» 이 없어서 판만으로는 어느 변형인지 정해지지 않는다.
    public enum Style: Sendable, CaseIterable {
        /// 밝은 판 — 회색 바 + g400 글자 (Figma `color=gray`)
        case gray
        /// 어두운 판 — 그린 바 + 흰 글자 (Figma `color=green1`)
        case greenOnDark
        /// g50 판 + 그린 4pt 바 + 14pt 글자, 오른쪽 «수정» (Figma `color=green2`)
        case block
    }

    private let text: String
    private let style: Style
    private let onEdit: (() -> Void)?

    /// - Parameters:
    ///   - text: 인용할 코멘트. 한 줄로 잘리고 넘치면 말줄임.
    ///   - style: Figma `color` 축.
    ///   - onEdit: «수정» 링크 동작 — `.block` 전용, 없으면 링크를 그리지 않는다.
    public init(_ text: String, style: Style = .gray, onEdit: (() -> Void)? = nil) {
        #if DEBUG
        assert(style == .block || onEdit == nil, "«수정» 링크는 .block 시안에만 있다.")
        #endif
        self.text = text
        self.style = style
        self.onEdit = onEdit
    }

    public var body: some View {
        switch style {
        case .gray, .greenOnDark: line
        case .block: block
        }
    }

    /// 얇은 바 + 12pt 한 줄.
    private var line: some View {
        HStack(spacing: Metric.gap) {
            Rectangle()
                .fill(style == .gray ? Color.quoteBarGray : Color.HilitGreen.g500)
                .frame(width: 2, height: 12)
            quotedText(.body9, foreground: style == .gray ? Color.GrayScale.g400 : Color.BlackWhite.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// g50 판 + 왼쪽 4pt 그린 바(판 높이 전체) + 14pt 글자 + «수정».
    private var block: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.HilitGreen.g500)
                .frame(width: .ds(.large))
            HStack(spacing: Metric.gap) {
                quotedText(.body6, foreground: Color.GrayScale.g800)
                if let onEdit {
                    Button(action: onEdit) {
                        Text("수정")
                            .underline()
                            .dsTypography(.body9)
                            .foregroundStyle(Color.GrayScale.g900)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, .ds(.p12))
            .padding(.trailing, .ds(.p8))
            .padding(.vertical, .ds(.p8))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.GrayScale.g50)
    }

    private func quotedText(_ typography: DSTypography, foreground: Color) -> some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.tail)
            .dsTypography(typography)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Metric {
        /// 바–글자 간격. Figma raw 6 — spacing 스케일에 없고 변수 바인딩도 없어 토큰화 보류.
        static let gap: CGFloat = 6
    }
}

private extension Color {
    /// `.gray` 바 색 #DEDEE1 — 팔레트 23색 밖(g100 #EBECF1 과 g200 #BCBEC6 사이)이고
    /// Figma 변수 미바인딩이라 승격 보류. 변수가 생기면 팔레트 토큰으로 갈아탄다.
    static let quoteBarGray = Color(red: 222 / 255, green: 222 / 255, blue: 225 / 255)
}

#Preview("light") {
    VStack(alignment: .leading, spacing: .ds(.p20)) {
        QuoteField("코멘트란입니다 코멘트란입니다 코멘트란입니다")
        QuoteField("코멘트란입니다 코멘트란입니다 코멘트란입니다", style: .block, onEdit: {})
        QuoteField("수정 없는 블록", style: .block)
        QuoteField("아주 긴 코멘트라서 한 줄에 들어가지 않고 말줄임으로 잘려야 하는 경우를 확인한다", style: .block, onEdit: {})
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity)
    .background(Color.BlackWhite.white)
}

#Preview("dark") {
    VStack(alignment: .leading, spacing: .ds(.p20)) {
        QuoteField("코멘트란입니다 코멘트란입니다 코멘트란입니다", style: .greenOnDark)
        QuoteField("아주 긴 코멘트라서 한 줄에 들어가지 않고 말줄임으로 잘려야 하는 경우를 확인한다", style: .greenOnDark)
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity)
    .background(Color.HilitBlack.b900)
}
