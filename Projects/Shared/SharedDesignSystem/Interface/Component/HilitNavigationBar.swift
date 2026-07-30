//
//  HilitNavigationBar.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/07/30.
//

import SwiftUI

// Figma «Navigationbar» 컴포넌트 세트 — icon 2446:7485 · text 3029:11189 · logo 3632:13967
/// 커스텀 내비게이션바 — 시스템 내비바 대신 화면 콘텐츠 최상단에 놓는 54pt 바.
///
/// 최종 시안은 3변형으로 닫혔고 뒤로가기 버튼이 없다(닫기 X 통일 — pop 은 하단 CTA·스와이프백 몫):
/// - **X | 타이틀 | +** — `HilitNavigationBar("타이틀", trailing: .plus { … }, onClose: { … })`
/// - **X | 타이틀 | 텍스트** — `trailing: .text("버튼") { … }`
/// - **로고 | 프로필** — `HilitNavigationBar.logo(onProfile:)` (루트 전용)
///
/// leading X 는 상수라 슬롯이 아니라 필수 액션(`onClose`)이다. 시안의 show 토글은
/// `trailing: nil`(기본). 아이콘 색변형(`default24`/`white24`)·타이틀색은 `theme` 이 파생하므로
/// 화면이 고르지 않는다 — 다크 배경에 검정 X 같은 조합이 표현 불가능하다.
///
/// `theme` 은 mini 버튼의 `.hilitSurface(.light/.dark)` 와 같은 «판 톤» 축이다.
/// 내비바는 Environment 가 아니라 파라미터로 받는다 — 빼먹으면 조용히 틀리는 물건이라 명시가 안전.
public struct HilitNavigationBar: View {
    /// 바가 놓이는 판의 톤 — 아이콘 색변형·타이틀색·`.filled` 배경색을 전부 파생한다.
    public enum Theme: Sendable {
        case light
        case dark
    }

    /// trailing 슬롯 — 시안의 두 종만. 다크 trailing 은 시안이 없어 DEBUG assert (필요 시 디자이너 확인 후 추가).
    public enum Trailing {
        case plus(action: () -> Void)
        case text(String, action: () -> Void)
    }

    /// 바 배경 — 기본은 투명(영상 풀블리드처럼 뒤 화면이 비쳐야 하는 케이스).
    /// 스크롤 화면은 콘텐츠가 바 밑으로 지나가므로 `.filled`(theme 색) 로 칠한다.
    /// 스크림(그라데이션) 시안이 생기면 case 추가로 확장한다.
    public enum Background: Sendable {
        case transparent
        case filled
    }

    private enum Content {
        case standard(title: String?, trailing: Trailing?, onClose: (() -> Void)?)
        case logo(onProfile: (() -> Void)?)
    }

    private let content: Content
    private let theme: Theme

    /// `onClose` 기본값용 — 스택에 있으면 pop, present 됐으면 dismiss 를 SwiftUI 가 자동 분기.
    /// 어느 쪽이든 리듀서에는 `popFrom(id:)`/`PresentationAction.dismiss` 액션으로 도착한다(우회 아님).
    @Environment(\.dismiss) private var dismiss

    /// 표준 바 — X(항상 표시) + 중앙 타이틀 + trailing 슬롯.
    ///
    /// `onClose` 생략 = 기본 동작(pop, 없으면 dismiss). 클로저 전달 = **override** —
    /// 확인 팝업을 먼저 띄우거나(리듀서가 `.userTappedClose` 를 가로챔) 플로우 전체를
    /// 종료(delegate)하는 화면은 자기 액션을 넘긴다. 패턴 예시는 `design/component/navigation.md`.
    public init(
        _ title: String? = nil,
        trailing: Trailing? = nil,
        theme: Theme = .light,
        onClose: (() -> Void)? = nil
    ) {
        #if DEBUG
        assert(!(theme == .dark && trailing != nil),
               "HilitNavigationBar: 다크 바의 trailing 시안이 없다 — 필요하면 디자이너 확인 후 추가.")
        #endif
        self.content = .standard(title: title, trailing: trailing, onClose: onClose)
        self.theme = theme
    }

    /// logo 변형 — Hilit 워드마크 + 우측 프로필 (Figma 3632:13967, 루트 전용이라 X 없음).
    public static func logo(onProfile: (() -> Void)? = nil) -> HilitNavigationBar {
        HilitNavigationBar(content: .logo(onProfile: onProfile), theme: .light)
    }

    private init(content: Content, theme: Theme) {
        self.content = content
        self.theme = theme
    }

    public var body: some View {
        HStack(spacing: 6) {
            switch content {
            case let .standard(title, trailing, onClose):
                iconSlot(closeIcon, action: onClose ?? { dismiss() }, alignment: .leading)
                centerTitle(title)
                trailingSlot(trailing)
            case let .logo(onProfile):
                Image.Logo.hilit
                    .resizable()
                    .scaledToFit()
                    .frame(width: 57, height: 24)
                Spacer(minLength: 0)
                if let onProfile {
                    iconSlot(Image.Profile.default, action: onProfile, alignment: .trailing)
                } else {
                    Color.clear.frame(width: 40)
                }
            }
        }
        // 슬롯 26(아이콘 24 + 상하 1) + 상하 p14 = 총 54 (Figma 실측).
        .frame(height: 26)
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p14))
    }

    // MARK: - theme 파생 값

    private var closeIcon: Image {
        switch theme {
        case .light: Image.Cancel.default24
        case .dark: Image.Cancel.white24
        }
    }

    private var titleColor: Color {
        switch theme {
        case .light: Color.HilitBlack.b800
        case .dark: Color.BlackWhite.white
        }
    }

    /// `.filled` 일 때 바 배경 — 화면 배경 토큰과 같은 값이라 이음새가 없다.
    var fillColor: Color {
        switch theme {
        case .light: Color.BlackWhite.white
        case .dark: Color.HilitBlack.b800
        }
    }

    // MARK: - 슬롯

    @ViewBuilder
    private func centerTitle(_ title: String?) -> some View {
        if let title {
            Text(title)
                .dsTypography(.sub7)
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        } else {
            Spacer(minLength: 0)
        }
    }

    /// 아이콘 슬롯은 폭 40 고정(시안 leading 컨테이너 값) — 비어 있어도 유지해 타이틀 중앙을 지킨다.
    private func iconSlot(_ image: Image, action: @escaping () -> Void, alignment: Alignment) -> some View {
        Button(action: action) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .frame(width: 40, alignment: alignment)
    }

    /// 텍스트 버튼만 내용 폭 — 시안도 hug 라 타이틀이 살짝 좌측으로 치우친다.
    @ViewBuilder
    private func trailingSlot(_ trailing: Trailing?) -> some View {
        switch trailing {
        case let .plus(action):
            iconSlot(Image.Plus.default24, action: action, alignment: .trailing)
        case let .text(label, action):
            Button(action: action) {
                Text(label)
                    .dsTypography(.body5)
                    .foregroundStyle(Color.GrayScale.g400)
                    .padding(.horizontal, .ds(.p8))
                    .padding(.vertical, .ds(.p4))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case nil:
            Color.clear.frame(width: 40)
        }
    }
}

// MARK: - 화면 부착 모디파이어

public extension View {
    /// 시스템 내비바를 숨기고 `HilitNavigationBar` 를 상단 safe area 에 얹는다.
    /// 화면은 바 내용(타이틀·trailing·onClose)만 선언하고, 배관(`navigationBarBackButtonHidden`·
    /// `toolbar(.hidden)`·`safeAreaInset`·스와이프백 delegate)은 여기가 소유한다.
    ///
    /// `navigationBarBackButtonHidden` 이 끄는 엣지 스와이프백은 `SwipeBackPolicy` 가
    /// 이 화면이 보이는 동안만 복구한다(전역 아님 — `UINavigationController+SwipeBack.swift`).
    ///
    /// `allowsSwipeBack: false` — 스와이프 pop 을 이 화면에서만 끈다.
    /// 스와이프는 버튼과 달리 화면의 «나가기 전 로직»(확인·제출)을 안 태우므로,
    /// pop 전에 되물을 게 있는 화면만 끈다. 상태 파생 값 가능(`!store.isUploading` 등).
    ///
    /// `onClose` 생략 = X 기본 동작(pop, 없으면 dismiss — `@Environment(\.dismiss)`).
    /// 클로저 전달 = override — 확인 팝업·플로우 종료 등 화면 리듀서가 닫기를 소유한다.
    func hilitNavigationBar(
        _ title: String? = nil,
        trailing: HilitNavigationBar.Trailing? = nil,
        theme: HilitNavigationBar.Theme = .light,
        background: HilitNavigationBar.Background = .transparent,
        allowsSwipeBack: Bool = true,
        onClose: (() -> Void)? = nil
    ) -> some View {
        attachHilitNavigationBar(
            HilitNavigationBar(title, trailing: trailing, theme: theme, onClose: onClose),
            background: background,
            allowsSwipeBack: allowsSwipeBack
        )
    }

    /// logo 변형(Hilit 워드마크 + 프로필) 부착 — 홈처럼 브랜드 바를 쓰는 루트 화면용.
    func hilitLogoNavigationBar(
        background: HilitNavigationBar.Background = .transparent,
        onProfile: (() -> Void)? = nil
    ) -> some View {
        // logo 변형은 루트 전용 — 루트는 pop 대상이 없어 스와이프백 스위치가 무의미.
        attachHilitNavigationBar(.logo(onProfile: onProfile), background: background, allowsSwipeBack: true)
    }

    private func attachHilitNavigationBar(
        _ bar: HilitNavigationBar,
        background: HilitNavigationBar.Background,
        allowsSwipeBack: Bool
    ) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            bar.background {
                if background == .filled {
                    bar.fillColor
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background {
            SwipeBackPolicy(allows: allowsSwipeBack)
        }
    }
}

// MARK: - Previews

#Preview("표준 — X만 / X+플러스 / X+텍스트") {
    VStack(spacing: 0) {
        HilitNavigationBar("타이틀", onClose: {})
        Divider()
        HilitNavigationBar("타이틀", trailing: .plus {}, onClose: {})
        Divider()
        HilitNavigationBar("타이틀", trailing: .text("버튼") {}, onClose: {})
        Divider()
        Spacer()
    }
}

#Preview("X 기본 동작 — onClose 생략 = pop") {
    NavigationStack {
        NavigationLink("다음 화면으로 push") {
            Text("X 를 누르면 pop (기본 동작)")
                .hilitNavigationBar("기본 X", background: .filled)
        }
    }
}

#Preview("다크 — trailing 없음") {
    VStack(spacing: 0) {
        HilitNavigationBar("타이틀", theme: .dark, onClose: {})
        Spacer()
    }
    .background(Color.HilitBlack.b800)
}

#Preview("logo — 워드마크·프로필") {
    VStack(spacing: 0) {
        HilitNavigationBar.logo(onProfile: {})
        Divider()
        Spacer()
    }
}

#Preview("배경 — filled vs transparent (스크롤 통과 대비)") {
    HStack(spacing: 0) {
        ScrollView {
            VStack { ForEach(0..<30) { Text("콘텐츠 \($0)").frame(maxWidth: .infinity) } }
        }
        .hilitNavigationBar("filled", background: .filled, onClose: {})

        ScrollView {
            VStack { ForEach(0..<30) { Text("콘텐츠 \($0)").frame(maxWidth: .infinity) } }
        }
        .hilitNavigationBar("transparent", onClose: {})
    }
}
