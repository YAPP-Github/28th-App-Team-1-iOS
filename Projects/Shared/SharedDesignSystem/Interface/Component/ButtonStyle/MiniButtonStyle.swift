//
//  MiniButtonStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

// Figma: «button-mini» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-739
//        «button-mini/with-icon» light 439-10204 · dark 439-10205 — 아이콘은 변형이 아니라 라벨 구성이다:
//        Button { HStack(spacing: .ds(.p8)) { Image.Video.default16; Text("영상 다시보기") } }

import SwiftUI

/// 소형 버튼 — h34 · body5 · px12/py8 · 직각 · hug.
/// Figma `light/dark` 축이 실제로 사는 유일한 티어 — 판은 `.hilitSurface(_:)` Environment 로 받고,
/// gray·disabled 팔레트가 판에 따라 바뀐다. pressed(black)는 `configuration.isPressed` 자동.
public struct MiniButtonStyle: ButtonStyle {
    /// 색 — Figma `color` 축. 판(surface)별 실제 팔레트는 아래 resolve 에서.
    public enum Tone: Sendable, CaseIterable {
        /// 검정 채움 (라이트 판 기본)
        case black
        /// 회색 — 라이트: g100 바탕 + b800 라벨, 다크: g900 바탕.
        /// 다크 라벨색은 `layout` 에 걸린다 — `.withIcon` 은 시안(439:10205)대로 흰색, 텍스트 전용은 g300.
        case gray
        /// 그린 채움
        case green
        /// 흰 채움 — 다크 판의 selected
        case white
        /// 다크 판 테두리형 (b800 바탕 + g500 테두리)
        case outlined
    }

    /// 라벨 구성 — Figma 가 마스터를 둘로 나눠 가로 여백이 다르다.
    public enum Layout: Sendable {
        /// 텍스트만 — px12 (`button-mini`)
        case textOnly
        /// 아이콘 + 텍스트 — px8 (`button-mini/with-icon`). 아이콘·간격은 라벨이 조립한다.
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
    private let layout: Layout

    public init(tone: Tone = .black, layout: Layout = .textOnly) {
        self.tone = tone
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

    private func resolve(pressed: Bool) -> Palette {
        guard isEnabled else {
            // disabled 는 색과 무관하게 판별 한 쌍으로 수렴한다.
            return surface == .dark
                ? Palette(background: Color.GrayScale.g800, foreground: Color.GrayScale.g500)
                : Palette(background: Color.GrayScale.g50, foreground: Color.GrayScale.g300)
        }
        switch tone {
        case .black:
            return Palette(background: pressed ? Color.GrayScale.g900 : Color.HilitBlack.b800,
                           foreground: Color.BlackWhite.white)
        case .gray:
            guard surface == .dark else {
                // Figma `button-mini/with-icon` light 439:10204 — g100 바탕 + b800 라벨.
                return Palette(background: Color.GrayScale.g100, foreground: Color.HilitBlack.b800)
            }
            // 다크 판 회색은 `with-icon` dark(439:10205)만 시안이 있고 라벨이 **흰색**이다.
            // 텍스트 전용 다크 회색은 확정 시안이 없어 기존 g300 을 유지한다 — 그래서 라벨색이 layout 에 걸린다.
            return Palette(background: Color.GrayScale.g900,
                           foreground: layout == .withIcon ? Color.BlackWhite.white : Color.GrayScale.g300)
        case .green:
            return Palette(background: Color.HilitGreen.g500, foreground: Color.HilitGreen.g800)
        case .white:
            return Palette(background: Color.BlackWhite.white, foreground: Color.HilitBlack.b800)
        case .outlined:
            return Palette(background: Color.HilitBlack.b800,
                           foreground: Color.GrayScale.g100,
                           border: Color.GrayScale.g500)
        }
    }
}

/// 초소형 버튼 — h26 · body5 · px8/py4 · 테두리 1.0 (Figma `status=sub` 티어).
public struct MiniSubButtonStyle: ButtonStyle {
    /// Figma `color` 축 — sub 티어는 3종뿐.
    public enum Tone: Sendable, CaseIterable {
        /// 흰 바탕 + g100 테두리
        case white
        /// 검정 바탕 + g900 테두리
        case black
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
    /// 소형 버튼. 판(light/dark)은 `.hilitSurface(_:)` 로, 아이콘 동반 시 `layout: .withIcon`.
    static func mini(
        _ tone: MiniButtonStyle.Tone = .black,
        layout: MiniButtonStyle.Layout = .textOnly
    ) -> Self {
        MiniButtonStyle(tone: tone, layout: layout)
    }
}

public extension ButtonStyle where Self == MiniSubButtonStyle {
    /// 초소형(sub) 버튼.
    static func miniSub(_ tone: MiniSubButtonStyle.Tone = .white) -> Self {
        MiniSubButtonStyle(tone: tone)
    }
}

#Preview("mini — 라이트/다크 판") {
    VStack(spacing: .ds(.p16)) {
        HStack(spacing: .ds(.p8)) {
            Button("버튼") {}.buttonStyle(.mini(.black))
            Button("버튼") {}.buttonStyle(.mini(.gray))
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
            Button("버튼") {}.buttonStyle(.mini(.white))
            Button("버튼") {}.buttonStyle(.mini(.outlined))
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
