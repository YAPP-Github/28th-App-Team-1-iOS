//
//  MessageCard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «message-card» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-1392
//        size 축 2종 — detail 435:1392 · mini 435:1401

import SwiftUI

/// AI 가 건네는 말 카드 — Figma «message-card» 435:1392 (`size` 축 2종).
///
/// `.detail` 은 b800 판 위 «36pt 분석 아이콘 + 서브타이틀·타이틀 / 본문», `.mini` 는 g800 판 위
/// «16pt 스파클 + 본문 한 줄». 두 판 색이 다르다 — 시안대로 케이스가 정한다.
///
/// Figma `subTitle`·`title`·`contentText` 축은 **값의 유무**로 표현한다(`nil` 이면 그 줄이 없다) —
/// `TitleBox` 와 같은 방식. 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라
/// 호출부 레이아웃 몫이다.
public struct MessageCard: View {
    /// Figma `size` 축. 값이 붙는 자리가 판마다 달라서 payload 를 케이스가 나른다.
    public enum Size: Sendable, Equatable {
        /// 큰 판 — b800 바탕. 세 줄 모두 `nil` 이면 아이콘만 남는다 (Figma `size=detail`)
        case detail(subtitle: String?, title: String?, contents: String?)
        /// 한 줄 판 — g800 바탕 + 그린 스파클 (Figma `size=mini`)
        case mini(String)
    }

    private let size: Size
    private let icon: Image

    /// - Parameters:
    ///   - size: Figma `size` 축.
    ///   - icon: `.detail` 왼쪽 36pt 아이콘. 시안은 instance-swap 슬롯이고 `hilit analyze` 패밀리에
    ///     `problem`·`success`·`aiSparkle` 세 판이 실재해서 열어 둔다(기본은 시안의 `problem`).
    ///     `.mini` 는 아이콘이 스파클로 닫혀 있어 이 값을 쓰지 않는다.
    public init(_ size: Size, icon: Image = Image.HilitAnalyze.problem) {
        self.size = size
        self.icon = icon
    }

    public var body: some View {
        switch size {
        case let .detail(subtitle, title, contents):
            detailBody(subtitle: subtitle, title: title, contents: contents)
        case let .mini(text):
            miniBody(text: text)
        }
    }

    private func detailBody(subtitle: String?, title: String?, contents: String?) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            HStack(spacing: .ds(.p8)) {
                // 36pt b800 사각이 에셋에 구워져 있다 — 판 색과 같아서 눈에는 글리프만 보인다.
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.iconSide, height: Metric.iconSide)
                VStack(alignment: .leading, spacing: Metric.headingGap) {
                    if let subtitle {
                        Text(subtitle)
                            .dsTypography(.body9)
                            .foregroundStyle(Color.GrayScale.g400)
                    }
                    if let title {
                        Text(title)
                            .dsTypography(.body1)
                            .foregroundStyle(Color.BlackWhite.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let contents {
                Text(contents)
                    .dsTypography(.body7)
                    .foregroundStyle(Color.GrayScale.g200)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.HilitBlack.b800)
    }

    private func miniBody(text: String) -> some View {
        HStack(alignment: .top, spacing: .ds(.p8)) {
            Image.Ai.green16
                .resizable()
                .scaledToFit()
                .frame(width: Metric.sparkleSide, height: Metric.sparkleSide)
            Text(text)
                .dsTypography(.body7)
                .foregroundStyle(Color.BlackWhite.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.GrayScale.g800)
    }

    private enum Metric {
        /// `.detail` 아이콘 한 변 36 — Figma `hilit analyze/36px`.
        static let iconSide: CGFloat = 36
        /// `.mini` 스파클 한 변 16 — Figma `ai sparkle/16px/green`.
        static let sparkleSide: CGFloat = 16
        /// 서브타이틀·타이틀 사이 2 — @ds(spacing) 스케일 밖 값(4·8·10·12·14·16·20·22·24·40).
        static let headingGap: CGFloat = 2
    }
}

// MARK: - Figma 원본 값 조정
//
// `.detail` 의 글자 열이 시안에선 폭 270 고정이다 — 335 판에서 «p12 + 아이콘 36 + gap8» 을 뺀
// 나머지(279)보다 좁아 오른쪽에 9 만큼 빈 자리가 생기는 값이다. 폭을 호출부에 맡기는 규칙과도
// 충돌해서 유연 폭(`maxWidth: .infinity`)으로 옮겼다 — 335 에서는 시안과 사실상 같게 보인다.

#Preview("message-card") {
    VStack(spacing: .ds(.p20)) {
        MessageCard(.detail(subtitle: "sub-title", title: "title", contents: "contents"))
        MessageCard(.mini("contents"))
        // show 축 — 줄을 하나씩 뺀 경우.
        MessageCard(.detail(subtitle: nil, title: "타이틀만 있는 경우", contents: "본문은 남는다"))
        MessageCard(.detail(subtitle: "서브타이틀만", title: nil, contents: nil))
        MessageCard(
            .detail(
                subtitle: "1번 질문",
                title: "답변에서 근거가 빠졌어요",
                contents: "아주 긴 본문이라서 한 줄에 들어가지 않고 다음 줄로 흘러야 하는 경우를 확인한다"
            ),
            icon: Image.HilitAnalyze.success
        )
        MessageCard(.mini("아주 긴 한 줄이라서 여러 줄로 흘러야 하는 경우를 확인한다. 아이콘은 위에 붙어 있다"))
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity)
    .background(Color.HilitBlack.b900)
}
