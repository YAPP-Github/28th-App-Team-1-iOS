//
//  InfoField.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/29.
//

import SwiftUI

/// 입력·화면 아래 붙는 안내/에러 줄 — Figma «info-field» 2085:3925 (`color` 축 2종).
///
/// 아이콘 16 + 12pt 한두 줄. 판 색이 의미를 나른다:
/// `.gray` g100 판 + g700 글자 + 검정 원 안 i(1974:628) ·
/// `.error` e200 판 + e300 테두리 1.2 + e500 글자 + **채운 빨간 원 안 흰 느낌표**(`issue/16px/error`).
///
/// 아이콘은 파라미터가 아니다 — 시안에 instance-swap 슬롯이 있지만 열어두면 시안에 없는
/// 조합이 만들어지므로 판 색에 묶어 닫았다(`TagLabel` 이 열려서 생긴 문제의 반대 선택).
/// `.error` 글리프는 마스터(2085:3924)의 «원 안 i» 가 아니라 **실사용 인스턴스 쪽**을 따른다 —
/// 아래 «Figma 원본 불일치» 참조.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct InfoField: View {
    /// Figma `color` 축.
    public enum Style: Sendable, CaseIterable {
        /// 회색 판 안내 (Figma `color=gray`)
        case gray
        /// 빨간 판 + 테두리 에러 (Figma `color=red`)
        case error
    }

    private let text: String
    private let style: Style

    /// - Parameters:
    ///   - text: 안내 문구. 폭이 모자라면 여러 줄로 흐른다(말줄임 없음).
    ///   - style: Figma `color` 축.
    public init(_ text: String, style: Style = .gray) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        HStack(spacing: .ds(.p8)) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: Metric.iconSide, height: Metric.iconSide)
            Text(text)
                .dsTypography(.body9)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, .ds(.p14))
        .padding(.vertical, .ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay {
            // 테두리는 `.error` 에만 있다. 모서리 0 — 캡슐이 아니다.
            if style == .error {
                Rectangle().strokeBorder(Color.Error.e300, lineWidth: .ds(.medium))
            }
        }
    }

    private var icon: Image {
        switch style {
        case .gray: Image.Info.default
        case .error: Image.Issue.error16
        }
    }

    private var foreground: Color {
        switch style {
        case .gray: Color.GrayScale.g700
        case .error: Color.Error.e500
        }
    }

    private var background: Color {
        switch style {
        case .gray: Color.GrayScale.g100
        case .error: Color.Error.e200
        }
    }

    private enum Metric {
        /// 아이콘 한 변 16 — Figma `info/16px`·`issue/16px`. 크기 축이 하나라 파라미터로 열지 않는다.
        static let iconSide: CGFloat = 16
    }
}

// MARK: - Figma 원본 불일치
//
// `.error` 아이콘이 **마스터와 인스턴스에서 다르다**. 마스터 «info-field/red»(2085:3924)는 원 안 i 를
// e500 으로 덮어쓴 것이고(그래서 아이콘 시트에 이름 붙은 변형이 없다 — `Image.Info.error` 주석 참조),
// 실제로 배치된 빨간 안내줄은 전부 «issue/16px/error»(채운 원 + 흰 느낌표)를 끼워 넣는다 —
// Part5 마이페이지의 업로드 불가 모달(435:8895)·업로드 실패 카드 아래 줄(439:13132·439:13299).
// 3:1 로 다수인 실사용 쪽을 따랐다(2026-08-01, 사용자 확인). 마스터가 정리되면 이 주석을 지운다.

#Preview {
    VStack(alignment: .leading, spacing: .ds(.p20)) {
        InfoField("텍스트를 입력해주세요")
        InfoField("텍스트를 입력해주세요", style: .error)
        InfoField("아주 긴 안내 문구라서 한 줄에 들어가지 않고 다음 줄로 흘러야 하는 경우를 확인한다", style: .error)
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity)
    .background(Color.BlackWhite.white)
}
