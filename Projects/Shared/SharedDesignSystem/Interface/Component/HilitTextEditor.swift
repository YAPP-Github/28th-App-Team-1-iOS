//
//  HilitTextEditor.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/30.
//

// Figma: «text-field» large https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2044-1623

import SwiftUI

/// 여러 줄 입력 박스 — Figma «text-field» large 2091:806. SwiftUI `TextEditor` 와 이름이 겹쳐 `Hilit` 접두.
///
/// 높이 158 고정(넘치면 안에서 스크롤) + 4변 테두리. 한 줄짜리 `HilitTextField` 와 달리
/// 시안에 포커스 바·클리어 버튼·의미 상태가 없어 그리지 않는다 — 상태가 필요해지면
/// 시안이 생긴 뒤에 축을 연다.
/// `maxLength` 를 주면 아래 오른쪽에 «n/max» 카운터를 그리고 초과 입력을 잘라낸다.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct HilitTextEditor: View {
    private let placeholder: String
    @Binding private var text: String
    private let maxLength: Int?

    /// - Parameters:
    ///   - placeholder: 빈 박스 안내 문구.
    ///   - text: 입력 값.
    ///   - maxLength: 주면 카운터 표시 + 초과 입력 잘라냄. 기본 nil(카운터 없음).
    public init(_ placeholder: String, text: Binding<String>, maxLength: Int? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: .ds(.p8)) {
            editor
            if let maxLength {
                Text(verbatim: "\(text.count)/\(maxLength)")
                    .dsTypography(.body9)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    private var editor: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .dsTypography(.body4)
            .foregroundStyle(Color.HilitBlack.b800)
            .padding(.horizontal, Metric.horizontalInset)
            .padding(.vertical, Metric.verticalInset)
            .frame(height: Metric.height)
            .background(Color.BlackWhite.white)
            .overlay {
                Rectangle()
                    .strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.medium))
            }
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .dsTypography(.body4)
                        .foregroundStyle(Color.GrayScale.g500)
                        .padding(.horizontal, .ds(.p16))
                        .padding(.vertical, .ds(.p14))
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: text) { _, newValue in
                if let maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
    }

    private enum Metric {
        /// 박스 높이 — Figma large 158 고정.
        static let height: CGFloat = 158
        /// 시안 좌우 여백 16 = 이 패딩 11 + UITextView lineFragmentPadding 5.
        static let horizontalInset: CGFloat = 11
        /// 시안 상하 여백 14 = 이 패딩 6 + UITextView textContainerInset 상하 8.
        static let verticalInset: CGFloat = 6
    }
}

/// 타이핑·카운터가 살아 움직이는 걸 보려면 상태가 필요하다 — 프리뷰 전용 껍데기.
private struct HilitTextEditorPreview: View {
    @State private var text = ""

    var body: some View {
        VStack(spacing: .ds(.p20)) {
            HilitTextEditor("텍스트를 입력해주세요", text: $text, maxLength: 300)
            HilitTextEditor("카운터 없는 박스", text: .constant(""))
        }
        .padding(.ds(.p20))
        .background(Color.BlackWhite.white)
    }
}

#Preview("text-field large — 카운터") {
    HilitTextEditorPreview()
}
