//
//  MiniButtonStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

// Figma: «button-mini» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-739
//        한 시트가 세 가족을 담는다 — 본체(color 행 × status 열) · with icon(light/dark) · sub(black/white/none).
//        본체·with icon 은 `MiniButtonStyle`(후자는 `layout: .withIcon`), sub 는 `MiniSubButtonStyle`.
//        «button-mini/with-icon» light 439-10204 · dark 439-10205 — 아이콘은 변형이 아니라 라벨 구성이다:
//        Button { HStack(spacing: .ds(.p8)) { Image.Video.default16; Text("영상 다시보기") } }

import SwiftUI

/// 소형 버튼 — h34 · body5 · px12/py8 · 직각 · hug. «온보딩 및 지인 피드백 버튼으로 사용».
///
/// Figma 시트가 **color 축(행) × status 축(열)** 두 축이라 타입도 둘로 나눈다:
/// `Tone`(black·filled·gray·green) × `Style`(default·outlined).
/// 나머지 두 열 pressed·disabled 는 **파라미터가 아니다** — `configuration.isPressed` /
/// `@Environment(\.isEnabled)` 가 자동 처리한다(버튼 티어 공통 규칙).
/// 판(light/dark)은 `.hilitSurface(_:)` Environment 로 받는다 — 다만 본체 행은 시트대로 판과 무관하게
/// 고정 배색이고, 판을 타는 건 시트가 light/dark 두 칸을 따로 그린 `with icon` 행뿐이다.
public struct MiniButtonStyle: ButtonStyle {
    /// Figma `color` 축(시트 행). 판(surface)별 실제 팔레트는 `resolve` 에서.
    public enum Tone: Sendable, CaseIterable {
        /// 검정 채움 (라이트 판 기본) — b800 바탕 + 흰 라벨
        case black
        /// 흰 채움 — 흰 바탕 + b800 라벨. 다크 판의 selected 로도 쓴다
        case filled
        /// 회색 — **텍스트 전용은 판과 무관하게 어두운 판**(g900 바탕 + g300 라벨). 시트 `gray` 행이
        /// 라이트 시트 위에서도 어둡게 그려져 있다. `.withIcon` 만 판을 탄다 — 시트가 그 행에
        /// light/dark 두 칸을 따로 두기 때문(아래 `Layout.withIcon`).
        case gray
        /// 그린 채움 — g500 바탕 + g800 라벨
        case green
    }

    /// Figma `status` 축(시트 열) 중 **호출부가 정하는 것**. pressed·disabled 는 자동이라 여기 없다.
    public enum Style: Sendable, CaseIterable {
        /// 채움 (기본)
        case `default`
        /// 테두리형 — 시안에 `black` 행에만 있다(b800 바탕 + g500 테두리 + g100 라벨).
        case outlined
    }

    /// 라벨 구성 — Figma 가 마스터를 둘로 나눠 가로 여백이 다르다.
    public enum Layout: Sendable {
        /// 텍스트만 — px12 (`button-mini`)
        case textOnly
        /// 아이콘 + 텍스트 — px8 (`button-mini/with-icon`). 아이콘·간격은 라벨이 조립한다.
        /// 시트의 light/dark 두 칸은 판이라 `.hilitSurface(_:)` 로 갈린다 —
        /// 시트 주석대로 다크는 AI 레포트, 라이트는 지인 피드백 보고서에서 쓴다.
        case withIcon

        var horizontalPadding: CGFloat {
            switch self {
            case .textOnly: .ds(.p12)
            case .withIcon: .ds(.p8)
            }
        }
    }

    /// 한 조합이 쓰는 색 묶음.
    private struct Palette {
        let background: Color
        let foreground: Color
        var border: Color?
    }

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.hilitSurface) private var surface

    private let tone: Tone
    private let style: Style
    private let layout: Layout

    public init(tone: Tone = .black, style: Style = .default, layout: Layout = .textOnly) {
        assert(
            style == .default || tone == .black,
            "outlined 는 시안에 black 행만 있다 — 다른 색이 필요하면 디자인 확인이 먼저다."
        )
        self.tone = tone
        self.style = style
        self.layout = layout
    }

    public func makeBody(configuration: Configuration) -> some View {
        let colors = resolve(pressed: configuration.isPressed)
        configuration.label
            .dsTypography(.body5)
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.vertical, .ds(.p8))
            .foregroundStyle(colors.foreground)
            .background(colors.background)
            .overlay {
                if let border = colors.border {
                    Rectangle().strokeBorder(border, lineWidth: .ds(.medium))
                }
            }
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    /// 시트의 한 칸을 고른다 — 열(status)이 행(color)을 이긴다.
    /// disabled → pressed → outlined 순으로 먼저 걸러지고, 남으면 색의 default 칸.
    private func resolve(pressed: Bool) -> Palette {
        guard isEnabled else {
            // 시트의 disabled 열은 두 칸뿐이고 서로 다르다 — black 은 밝은 판(g50+g300),
            // gray 는 제 어두운 판을 유지(g800+g500). 시안 없는 색은 밝은 쪽으로 수렴시키되,
            // 다크 화면에 얹힌 버튼은 판을 따라 어두운 쪽을 쓴다.
            return tone == .gray || surface == .dark
                ? Palette(background: Color.GrayScale.g800, foreground: Color.GrayScale.g500)
                : Palette(background: Color.GrayScale.g50, foreground: Color.GrayScale.g300)
        }
        if style == .outlined {
            // black×outlined 만 시안에 있다(init assert). 눌림은 채움과 같은 g900 으로 어둡게.
            return Palette(background: pressed ? Color.GrayScale.g900 : Color.HilitBlack.b800,
                           foreground: Color.GrayScale.g100,
                           border: Color.GrayScale.g500)
        }
        if pressed, tone == .black {
            // pressed 칸은 시안에 black 행만 있다 — 나머지 색은 default 칸을 그대로 쓴다.
            return Palette(background: Color.GrayScale.g900, foreground: Color.BlackWhite.white)
        }
        switch tone {
        case .black:
            return Palette(background: Color.HilitBlack.b800, foreground: Color.BlackWhite.white)
        case .filled:
            return Palette(background: Color.BlackWhite.white, foreground: Color.HilitBlack.b800)
        case .gray:
            // 시트가 gray 를 두 곳에 그린다 — 본체 `gray` 행(어두운 판 고정)과 `with icon` 행(light/dark 두 칸).
            // 그래서 이 색만 팔레트가 `layout` 에 걸린다.
            guard layout == .withIcon else {
                return Palette(background: Color.GrayScale.g900, foreground: Color.GrayScale.g300)
            }
            return surface == .dark
                // with-icon dark 439:10205 — 라벨이 흰색이다.
                ? Palette(background: Color.GrayScale.g900, foreground: Color.BlackWhite.white)
                // with-icon light 439:10204 — g100 바탕 + b800 라벨.
                : Palette(background: Color.GrayScale.g100, foreground: Color.HilitBlack.b800)
        case .green:
            return Palette(background: Color.HilitGreen.g500, foreground: Color.HilitGreen.g800)
        }
    }
}

/// 초소형 버튼 — h26 · body5 · px8/py4 · 테두리 1.0. 같은 button-mini 시트의 `sub` 행.
/// 이 행은 status 축이 없어(칸이 색 3개뿐) 타입도 `Tone` 하나다 — 본체(`MiniButtonStyle`)와 다른 점.
public struct MiniSubButtonStyle: ButtonStyle {
    /// Figma `color` 축 — sub 행은 3종뿐. 순서는 시트 그대로.
    public enum Tone: Sendable, CaseIterable {
        /// 검정 바탕 + g900 테두리
        case black
        /// 흰 바탕 + g100 테두리
        case white
        /// 투명 — 배경·테두리 없음, 회색 글자
        case none
    }

    @Environment(\.isEnabled) private var isEnabled

    private let tone: Tone

    public init(tone: Tone = .white) {
        self.tone = tone
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(.body5)
            .padding(.horizontal, .ds(.p8))
            .padding(.vertical, .ds(.p4))
            .foregroundStyle(foreground)
            .background(background)
            .overlay {
                if let border {
                    Rectangle().strokeBorder(border, lineWidth: .ds(.small))
                }
            }
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        guard isEnabled else { return Color.GrayScale.g300 }
        switch tone {
        case .white: return Color.HilitBlack.b800
        case .black: return Color.BlackWhite.white
        case .none: return Color.GrayScale.g400
        }
    }

    private var background: Color {
        switch tone {
        case .white: isEnabled ? Color.BlackWhite.white : Color.GrayScale.g50
        case .black: isEnabled ? Color.HilitBlack.b800 : Color.GrayScale.g50
        case .none: .clear
        }
    }

    private var border: Color? {
        switch tone {
        case .white: Color.GrayScale.g100
        case .black: Color.GrayScale.g900
        case .none: nil
        }
    }
}

public extension ButtonStyle where Self == MiniButtonStyle {
    /// 소형 버튼 — 색(`tone`) × 상태(`style`) 두 축. pressed·disabled 는 넘기지 않는다(자동).
    /// 판(light/dark)은 `.hilitSurface(_:)` 로, 아이콘 동반 시 `layout: .withIcon`.
    static func mini(
        _ tone: MiniButtonStyle.Tone = .black,
        style: MiniButtonStyle.Style = .default,
        layout: MiniButtonStyle.Layout = .textOnly
    ) -> Self {
        MiniButtonStyle(tone: tone, style: style, layout: layout)
    }
}

public extension ButtonStyle where Self == MiniSubButtonStyle {
    /// 초소형(sub) 버튼.
    static func miniSub(_ tone: MiniSubButtonStyle.Tone = .white) -> Self {
        MiniSubButtonStyle(tone: tone)
    }
}

#Preview("mini — 시트 매트릭스(color × status)") {
    // Figma 시트 그대로: 행 = color(black·filled·gray·green), 열 = default / disabled / outlined.
    // pressed 열은 파라미터가 없어 프리뷰로 못 만든다 — 실기기에서 눌러 확인한다.
    Grid(alignment: .leading, horizontalSpacing: .ds(.p12), verticalSpacing: .ds(.p12)) {
        GridRow {
            Text("").frame(width: 44)
            Text("default").dsTypography(.body6)
            Text("disabled").dsTypography(.body6)
            Text("outlined").dsTypography(.body6)
        }
        ForEach(MiniButtonStyle.Tone.allCases, id: \.self) { tone in
            GridRow {
                Text(String(describing: tone)).dsTypography(.body6).frame(width: 44, alignment: .leading)
                Button("버튼") {}.buttonStyle(.mini(tone))
                Button("버튼") {}.buttonStyle(.mini(tone)).disabled(true)
                if tone == .black {
                    Button("버튼") {}.buttonStyle(.mini(tone, style: .outlined))
                }
            }
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}

#Preview("mini — 라이트/다크 판") {
    VStack(spacing: .ds(.p16)) {
        HStack(spacing: .ds(.p8)) {
            Button("버튼") {}.buttonStyle(.mini(.black))
            Button("버튼") {}.buttonStyle(.mini(.gray))
            Button("버튼") {}.buttonStyle(.mini(.green))
            Button("버튼") {}.buttonStyle(.mini(.black, style: .outlined))
            Button("비활성") {}.buttonStyle(.mini(.black)).disabled(true)
        }
        // with-icon — 라이트 판(439:10204)과 다크 판(439:10205). 다크 라벨은 흰색이다.
        // @ds(image): 다크 판 시안 아이콘은 흰색인데 `video/16px/white` 에셋이 아직 없다 —
        //             에셋이 들어오면 아래 다크 쪽 `Image.Video.default16` 을 그것으로 바꾼다.
        HStack(spacing: .ds(.p8)) {
            Button {} label: {
                HStack(spacing: .ds(.p8)) {
                    Image.Video.default16
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("영상 다시보기")
                }
            }
            .buttonStyle(.mini(.gray, layout: .withIcon))

            Button {} label: {
                HStack(spacing: .ds(.p8)) {
                    Image.Video.default16
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("영상 다시보기")
                }
            }
            .buttonStyle(.mini(.gray, layout: .withIcon))
            .hilitSurface(.dark)
        }
        HStack(spacing: .ds(.p8)) {
            Button("버튼") {}.buttonStyle(.mini(.gray))
            Button("버튼") {}.buttonStyle(.mini(.green))
            Button("버튼") {}.buttonStyle(.mini(.filled))
            Button("버튼") {}.buttonStyle(.mini(.black, style: .outlined))
        }
        .padding(.ds(.p12))
        .background(Color.HilitBlack.b900)
        .hilitSurface(.dark)

        HStack(spacing: .ds(.p8)) {
            Button("버튼") {}.buttonStyle(.miniSub(.white))
            Button("버튼") {}.buttonStyle(.miniSub(.black))
            Button("버튼") {}.buttonStyle(.miniSub(.none))
        }
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
