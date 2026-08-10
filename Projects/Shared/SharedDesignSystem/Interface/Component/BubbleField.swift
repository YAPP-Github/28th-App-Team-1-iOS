//
//  BubbleField.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

import SwiftUI

/// 말풍선 필드 — Figma «bubble-field» 2000:7532 의 상태 5종 1:1.
/// 공통: 직각 모서리 · 가로 패딩 14 · body5(SemiBold 14) 흰 텍스트 중앙정렬.
/// 크기 티어는 둘 — `.wide` 폭 274 고정·세로 패딩 12, `.mini` 내용폭(hug)·세로 패딩 8.
/// 표출 위치·표출/해제 타이밍은 호출부 책임(예: CTA 위 10pt, 2초 자동 해제).
public struct BubbleField: View {
    /// 크기 티어 — Figma `status` 축을 «폭 274 고정»(none/top/bottom) 과 «내용폭»(mini) 으로 갈랐다.
    public enum Kind: Equatable {
        /// 폭 274 고정 · 세로 패딩 12. 고르는 건 꼬리 위치뿐. Figma status=none/top/bottom.
        case wide(tail: Tail)
        /// 내용폭(hug) · 세로 패딩 8 · 꼬리는 항상 좌하단. Figma status=mini(light)/status5(dark).
        case mini(mood: Mood)
    }

    /// `.wide` 꼬리 위치 — `.top` 은 좌상단, `.bottom` 은 우하단. 시안이 좌우를 달리 두었다(대칭 아님).
    public enum Tail: Equatable {
        case none
        case top
        case bottom
    }

    /// `.mini` 배경 톤 — light b800 / dark g900. `.wide` 는 시안에 light 만 있다.
    public enum Mood: Equatable {
        case light
        case dark
    }

    /// Figma 고정 폭(status=none/top/bottom).
    private static let wideWidth: CGFloat = 274
    /// 꼬리 조각 크기 — Figma tail SVG 는 97×11 프레임이고 삼각형은 그 안 x40..57 구간뿐이다.
    private static let tailSize = CGSize(width: 17, height: 11)
    /// 꼬리가 붙는 변의 기준 모서리에서 안쪽으로 들어온 거리(위 SVG 의 40). 대응 spacing 토큰 없어 리터럴.
    /// 표출 위치가 호출부 책임이라 **공개**한다 — 꼬리 끝을 무언가에 겨누려면 이 값이 필요하다.
    public static let tailInset: CGFloat = 40

    private let message: String
    private let kind: Kind

    /// - Parameters:
    ///   - message: 말풍선 문구.
    ///   - kind: 크기 티어와 꼬리/톤. 기본은 꼬리 없는 폭 274 토스트.
    public init(_ message: String, _ kind: Kind = .wide(tail: .none)) {
        self.message = message
        self.kind = kind
    }

    public var body: some View {
        switch kind {
        case .wide(.none):
            box
        case .wide(.top):
            VStack(alignment: .leading, spacing: 0) {
                tail(.topTrailing)
                    .padding(.leading, Self.tailInset)
                box
            }
        case .wide(.bottom):
            VStack(alignment: .trailing, spacing: 0) {
                box
                tail(.bottomTrailing)
                    .padding(.trailing, Self.tailInset)
            }
        case .mini:
            VStack(alignment: .leading, spacing: 0) {
                box
                tail(.bottomLeading)
                    .padding(.leading, Self.tailInset)
            }
        }
    }

    private var box: some View {
        Text(message)
            .dsTypography(.body5)
            .foregroundStyle(Color.BlackWhite.white)
            .multilineTextAlignment(.center)
            // `.wide` 는 274 안에서 텍스트가 폭을 다 쓰고 줄바꿈, `.mini` 는 내용폭 그대로.
            .frame(maxWidth: isWide ? CGFloat.infinity : nil)
            .padding(.horizontal, .ds(.p14))
            .padding(.vertical, isWide ? .ds(.p12) : .ds(.p8))
            .background(background)
            .frame(width: isWide ? Self.wideWidth : nil)
    }

    private func tail(_ tip: BubbleTail.Tip) -> some View {
        BubbleTail(tip: tip)
            .fill(background)
            .frame(width: Self.tailSize.width, height: Self.tailSize.height)
    }

    private var isWide: Bool {
        if case .wide = kind {
            return true
        }
        return false
    }

    private var background: Color {
        if case .mini(.dark) = kind {
            return Color.GrayScale.g900
        }
        return Color.HilitBlack.b800
    }
}

/// 말풍선 꼬리 — 17×11 직각삼각형. 직각을 뺀 세 꼭짓점이 삼각형이고, `tip` 의 마주 변이 말풍선에 붙는다.
/// 조각 단독으로는 «어느 쪽이 뾰족한가» 뿐이라 공개하지 않는다 — 배치 규칙은 `BubbleField` 가 갖는다.
private struct BubbleTail: Shape {
    enum Tip {
        case bottomTrailing
        case bottomLeading
        case topTrailing
    }

    let tip: Tip

    func path(in rect: CGRect) -> Path {
        Path { path in
            switch tip {
            case .bottomTrailing:
                // Figma `d="M57 11L40 0L57 0Z"` — 윗변이 말풍선 밑면에 붙는다.
                path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            case .bottomLeading:
                // Figma `d="M40 11L57 0L40 0Z"` — 위를 좌우로 뒤집은 형태(mini 전용).
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            case .topTrailing:
                // status=top — bottomTrailing 을 위아래로 뒤집어 아랫변이 말풍선 윗면에 붙는다.
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            path.closeSubpath()
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .ds(.p20)) {
        BubbleField("텍스트를 입력해주세요", .wide(tail: .bottom))
        BubbleField("텍스트를 입력해주세요", .wide(tail: .top))
        BubbleField("텍스트를 입력해주세요")
        HStack(spacing: .ds(.p16)) {
            BubbleField("텍스트를 입력해주세요", .mini(mood: .light))
            BubbleField("텍스트를 입력해주세요", .mini(mood: .dark))
        }
    }
    .padding(.ds(.p16))
    .background(Color.GrayScale.g700)
}
