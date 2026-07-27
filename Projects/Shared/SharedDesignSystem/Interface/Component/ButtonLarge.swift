//
//  ButtonLarge.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

// Figma: «ButtonLarge_bottom» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=1941-3256
//        «ButtonLarge_modal»  https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2302-5987

import SwiftUI

/// 대형 버튼이 놓이는 자리 — 여백과 안전영역 처리가 갈린다.
public enum ButtonLargeKind: Sendable {
    /// 화면 하단 풀블리드. px24 · 세로 비대칭 · 배경이 하단 안전영역까지 내려간다.
    case bottom
    /// 모달 안. px8 · 세로 대칭 16.
    case modal
}

/// 대형 단일 버튼 형태.
public enum ButtonLargeStyle: Sendable {
    case filled
    /// 흰 바탕 + 검정 테두리. **`.bottom` 전용** (모달엔 시안이 없다).
    case outlined
}

/// 대형 2버튼 배색.
public enum ButtonLargePairTone: Sendable {
    /// 검정 공유 배경 + 흰 라벨
    case dark
    /// 회색 공유 배경 + 검정 라벨. **`.bottom` 전용**
    case gray
    /// 왼쪽 회색 · 오른쪽 검정 반반 (divider 없음)
    case twoColor
}

/// 대형 버튼 — 화면 하단 CTA(`.bottom`)와 모달 확인(`.modal`). h55 · sub7 · 직각 · 가로 꽉 참.
///
/// ```swift
/// ButtonLarge("피드백 시작하기", .bottom) { }
/// ButtonLarge("다시 연습하기", .bottom, style: .outlined) { }
/// ButtonLarge(.modal, tone: .twoColor) {
///     Button("취소") { }
/// } trailing: {
///     Button("삭제") { }.disabled(true)     // 한쪽만 비활성 — 자식 modifier 로 표현
/// }
/// ```
///
/// **왜 ButtonStyle 이 아니라 View 인가**: 2버튼 변형이 divider·반반 배경·슬롯 2개를 가져서
/// 버튼 하나를 꾸미는 `ButtonStyle` 로는 표현이 안 된다. 단일만 스타일로 두면 한 Figma 가족이
/// 두 메커니즘으로 쪼개지므로 타입 하나로 합쳤다. 내부 세그먼트는 여전히 `ButtonStyle` 로 눌림을 굴린다.
///
/// 상태는 손대지 않는다 — pressed·disabled 는 자동이고, 로딩은 `.hilitButtonLoading(_:)`.
public struct ButtonLarge<Leading: View, Trailing: View>: View {
    // 제네릭 안에 중첩하면 특수화마다 다른 타입이 돼 내부 스타일과 안 맞물린다 — 파일 스코프에 두고 별칭만.
    public typealias Kind = ButtonLargeKind
    public typealias Style = ButtonLargeStyle
    public typealias PairTone = ButtonLargePairTone

    private enum Content {
        case single(title: String, style: Style, action: () -> Void)
        case pair(tone: PairTone)
    }

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.hilitButtonIsLoading) private var isLoading

    private let kind: Kind
    private let content: Content
    private let leading: Leading
    private let trailing: Trailing

    public var body: some View {
        Group {
            switch content {
            case let .single(title, style, action):
                single(title: title, style: style, action: action)
            case let .pair(tone):
                pair(tone: tone)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 단일

    private func single(title: String, style: Style, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(SingleStyle(kind: kind, style: style, isEnabled: isEnabled, isLoading: isLoading))
    }

    // MARK: - 2버튼

    private func pair(tone: PairTone) -> some View {
        HStack(spacing: tone.dividerColor == nil ? 0 : .ds(.p8)) {
            leading
                .buttonStyle(SegmentStyle(tone: tone, side: .leading))
            if let dividerColor = tone.dividerColor {
                // @ds(spacing): 1×25 — 두 라벨 사이 구분선 (토큰 없음)
                Rectangle()
                    .fill(dividerColor)
                    .frame(width: 1, height: 25)
            }
            trailing
                .buttonStyle(SegmentStyle(tone: tone, side: .trailing))
        }
        .padding(.horizontal, kind.horizontalPadding)
        .padding(.top, kind == .bottom ? .ds(.p20) : .ds(.p16))
        .padding(.bottom, kind == .bottom ? .ds(.p10) : .ds(.p16))
        .background {
            if let shared = tone.sharedBackground {
                shared.ignoresSafeArea(edges: kind.safeAreaEdges)
            }
        }
    }
}

// MARK: - init

public extension ButtonLarge where Leading == EmptyView, Trailing == EmptyView {
    /// 단일 버튼.
    init(_ title: String, _ kind: Kind, style: Style = .filled, action: @escaping () -> Void) {
        #if DEBUG
        assert(!(kind == .modal && style == .outlined), "모달에는 outlined 시안이 없다 — .bottom 을 쓰거나 .filled 로.")
        #endif
        self.kind = kind
        self.content = .single(title: title, style: style, action: action)
        self.leading = EmptyView()
        self.trailing = EmptyView()
    }
}

public extension ButtonLarge {
    /// 2버튼. 한쪽만 비활성은 해당 자식에 `.disabled(true)`.
    init(
        _ kind: Kind,
        tone: PairTone = .dark,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        #if DEBUG
        assert(!(kind == .modal && tone == .gray), "모달에는 gray 페어 시안이 없다.")
        #endif
        self.kind = kind
        self.content = .pair(tone: tone)
        self.leading = leading()
        self.trailing = trailing()
    }
}

// MARK: - 스펙

private extension ButtonLargeKind {
    var horizontalPadding: CGFloat {
        switch self {
        case .bottom: .ds(.p24)
        case .modal: .ds(.p8)
        }
    }

    /// 하단 CTA 만 배경이 안전영역을 덮는다.
    var safeAreaEdges: Edge.Set {
        switch self {
        case .bottom: .bottom
        case .modal: []
        }
    }
}

private extension ButtonLargePairTone {
    /// 반반(twoColor)은 세그먼트가 각자 칠하므로 공유 배경이 없다.
    var sharedBackground: Color? {
        switch self {
        case .dark: Color.HilitBlack.b800
        case .gray: Color.GrayScale.g50
        case .twoColor: nil
        }
    }

    var dividerColor: Color? {
        switch self {
        case .dark: Color.GrayScale.g800
        case .gray: Color.GrayScale.g200
        case .twoColor: nil
        }
    }
}

// MARK: - 내부 스타일

/// 단일 버튼 — 배경·테두리·눌림·비활성·로딩을 전부 여기서 굴린다.
private struct SingleStyle: ButtonStyle {
    let kind: ButtonLargeKind
    let style: ButtonLargeStyle
    let isEnabled: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(.sub7)
            .opacity(isLoading ? 0 : 1)
            .overlay { if isLoading { ProgressView().tint(foreground) } }
            .frame(maxWidth: .infinity, minHeight: DSTypography.sub7.lineHeight)
            .padding(.horizontal, kind.horizontalPadding)
            .padding(.top, kind == .bottom ? .ds(.p22) : .ds(.p16))
            .padding(.bottom, kind == .bottom ? .ds(.p10) : .ds(.p16))
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed).ignoresSafeArea(edges: kind.safeAreaEdges))
            .overlay {
                if style == .outlined {
                    // @ds(spacing): 1.5 — outlined 테두리, Figma outline-sb (DSOutline 은 1.2 다음이 4)
                    Rectangle().strokeBorder(isEnabled ? Color.HilitBlack.b800 : Color.GrayScale.g300, lineWidth: 1.5)
                }
            }
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    private var foreground: Color {
        guard isEnabled else { return Color.GrayScale.g300 }
        return style == .filled ? Color.BlackWhite.white : Color.HilitBlack.b800
    }

    private func background(pressed: Bool) -> Color {
        guard isEnabled else {
            return style == .filled ? Color.GrayScale.g50 : Color.BlackWhite.white
        }
        switch style {
        case .filled: return pressed ? Color.GrayScale.g900 : Color.HilitBlack.b800
        case .outlined: return pressed ? Color.GrayScale.g100 : Color.BlackWhite.white
        }
    }
}

/// 2버튼 한쪽 — 배경·divider 는 컨테이너 몫이라 라벨색과 반반 배경만 맡는다.
private struct SegmentStyle: ButtonStyle {
    enum Side { case leading, trailing }

    @Environment(\.isEnabled) private var isEnabled

    let tone: ButtonLargePairTone
    let side: Side

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(.sub7)
            .frame(maxWidth: .infinity, minHeight: DSTypography.sub7.lineHeight)
            .foregroundStyle(foreground)
            .background {
                if let ownBackground { ownBackground }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }

    private var foreground: Color {
        guard isEnabled else {
            // Figma 2button-1disabled 실측 — 어두운 판은 g400, 밝은 판은 g300.
            return tone == .gray ? Color.GrayScale.g300 : Color.GrayScale.g400
        }
        switch tone {
        case .dark: return Color.BlackWhite.white
        case .gray: return Color.HilitBlack.b800
        case .twoColor: return side == .leading ? Color.GrayScale.g700 : Color.BlackWhite.white
        }
    }

    /// 반반일 때만 세그먼트가 자기 배경을 칠한다.
    private var ownBackground: Color? {
        guard tone == .twoColor else { return nil }
        return side == .leading ? Color.GrayScale.g50 : Color.HilitBlack.b800
    }
}

#Preview("bottom — 단일") {
    VStack(spacing: .ds(.p16)) {
        ButtonLarge("피드백 시작하기", .bottom) {}
        ButtonLarge("다시 연습하기", .bottom, style: .outlined) {}
        ButtonLarge("비활성", .bottom) {}.disabled(true)
        ButtonLarge("전송 중", .bottom) {}.hilitButtonLoading(true)
    }
    .background(Color.BlackWhite.white)
}

#Preview("bottom — 2버튼") {
    VStack(spacing: .ds(.p16)) {
        ButtonLarge(.bottom, tone: .dark) {
            Button("아니오") {}
        } trailing: {
            Button("네") {}
        }
        ButtonLarge(.bottom, tone: .dark) {
            Button("아니오") {}
        } trailing: {
            Button("네") {}.disabled(true)
        }
        ButtonLarge(.bottom, tone: .gray) {
            Button("취소") {}
        } trailing: {
            Button("확인") {}
        }
        ButtonLarge(.bottom, tone: .twoColor) {
            Button("취소") {}
        } trailing: {
            Button("삭제") {}
        }
    }
    .background(Color.BlackWhite.white)
}

#Preview("modal") {
    VStack(spacing: 0) {
        Color.BlackWhite.white.frame(height: 80)
        ButtonLarge("다음", .modal) {}
        ButtonLarge("비활성", .modal) {}.disabled(true)
        ButtonLarge(.modal, tone: .twoColor) {
            Button("취소") {}
        } trailing: {
            Button("삭제") {}
        }
    }
    .frame(width: 335)
}
