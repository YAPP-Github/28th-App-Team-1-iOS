//
//  HilitNavigationBar.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/07/30.
//

import SwiftUI

// Figma «Navigationbar» 컴포넌트 세트 3029:11188 — icon 2446:7485 · text 3029:11189 · logo 3632:13967
/// 내비바 네임스페이스 — 시안 높이가 44(슬롯 26 + 상하 9, 시스템 표준)로 닫히면서
/// 커스텀 바를 걷어내고 **시스템 내비바에 내용만 꽂는다**. 부착 모디파이어 3종:
/// - push 화면(NavigationStack 안): `.hilitNavigationBar` — 시스템 바
/// - 루트 브랜드 바: `.hilitLogoNavigationBar` — 시스템 바
/// - present 화면(스택 밖 cover/sheet): `.hilitPresentedNavigationBar` — 시스템 바가
///   안 그려지는 자리라 같은 룩의 바를 `safeAreaInset` 으로 직접 얹는다
///
/// 바를 View 로 직접 배치하는 API 는 없다 — 부착은 항상 모디파이어.
///
/// 최종 시안은 3변형이고 뒤로가기 버튼이 없다(닫기 X 통일 — pop 은 하단 CTA·스와이프백 몫):
/// - **X | 타이틀 | +** — `.hilitNavigationBar("타이틀", trailing: .plus { … }, onClose: { … })`
/// - **X | 타이틀 | 텍스트** — `trailing: .text("버튼") { … }`
/// - **로고 | 프로필** — `.hilitLogoNavigationBar(onProfile:)` (루트 전용)
///
/// leading X 는 상수라 슬롯이 아니라 필수 액션(`onClose`)이다. 시안의 show 토글은
/// `trailing: nil`(기본). 아이콘 색변형(`default24`/`white24`)·타이틀색은 `theme` 이 파생하므로
/// 화면이 고르지 않는다 — 다크 배경에 검정 X 같은 조합이 표현 불가능하다.
///
/// `theme` 은 mini 버튼의 `.hilitSurface(.light/.dark)` 와 같은 «판 톤» 축이다.
/// 내비바는 Environment 가 아니라 파라미터로 받는다 — 빼먹으면 조용히 틀리는 물건이라 명시가 안전.
///
/// 좌우 여백은 시스템 바 마진을 그대로 쓴다 — 시안 px20 과 수 pt 차이가 있지만
/// «기본 UI 를 토대로 쓴다»는 결정(2026-07-31)에 따라 시스템 값을 받아들인다.
public enum HilitNavigationBar {
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
}

// MARK: - theme 파생 값

extension HilitNavigationBar.Theme {
    var closeIcon: Image {
        switch self {
        case .light: Image.Cancel.default24
        case .dark: Image.Cancel.white24
        }
    }

    var titleColor: Color {
        switch self {
        case .light: Color.HilitBlack.b800
        case .dark: Color.BlackWhite.white
        }
    }

    /// `.filled` 일 때 바 배경 — 화면 배경 토큰과 같은 값이라 이음새가 없다.
    var fillColor: Color {
        switch self {
        case .light: Color.BlackWhite.white
        case .dark: Color.HilitBlack.b800
        }
    }

    /// 상태바 글자색이 바 톤을 따라오게 시스템에 알려주는 값.
    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - 화면 부착 모디파이어

public extension View {
    /// 시스템 내비바에 표준 변형(X + 중앙 타이틀 + trailing 슬롯)을 꽂는다.
    /// 화면은 바 내용(타이틀·trailing·onClose)만 선언하고, 배관(타이틀 스타일·시스템 백버튼 숨김·
    /// 배경 visibility·스와이프백 delegate)은 여기가 소유한다.
    ///
    /// **NavigationStack 안에서만 그려진다** — cover/sheet 로 단독 present 되는 화면은
    /// 스택으로 감싸서 올린다(온보딩 위저드처럼). 스택 밖이면 바가 조용히 안 나온다.
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
        #if DEBUG
        assert(!(theme == .dark && trailing != nil),
               "HilitNavigationBar: 다크 바의 trailing 시안이 없다 — 필요하면 디자이너 확인 후 추가.")
        #endif
        return modifier(HilitNavigationBarModifier(
            bar: .standard(title: title, trailing: trailing, onClose: onClose),
            theme: theme,
            background: background,
            allowsSwipeBack: allowsSwipeBack
        ))
    }

    /// logo 변형(Hilit 워드마크 + 프로필) 부착 — 홈처럼 브랜드 바를 쓰는 루트 화면용.
    func hilitLogoNavigationBar(
        background: HilitNavigationBar.Background = .transparent,
        onProfile: (() -> Void)? = nil
    ) -> some View {
        // logo 변형은 루트 전용 — 루트는 pop 대상이 없어 스와이프백 스위치가 무의미.
        modifier(HilitNavigationBarModifier(
            bar: .logo(onProfile: onProfile),
            theme: .light,
            background: background,
            allowsSwipeBack: true
        ))
    }

    /// present 된 화면(스택 밖 — fullScreenCover/sheet 단독)용 수동 내비바.
    /// 시스템 바는 NavigationStack 밖에서 안 그려지므로, 같은 룩(44pt)의 바를
    /// `safeAreaInset` 으로 직접 얹는다. push 화면은 `.hilitNavigationBar` 를 쓴다.
    ///
    /// 시스템 경로와 다른 점:
    /// - 좌우 여백이 시안값(px20) — 시스템 바 마진과 수 pt 차이
    /// - 스택 밖이라 스와이프백 개념이 없다(`allowsSwipeBack` 파라미터 없음)
    /// - 상태바 글자색(colorScheme)은 화면이 소유 — 다크 화면이면 화면에서 처리
    ///
    /// `onClose` 생략 = X 기본 동작(dismiss). 클로저 전달 = override — 리듀서가 닫기를 소유.
    func hilitPresentedNavigationBar(
        _ title: String? = nil,
        trailing: HilitNavigationBar.Trailing? = nil,
        theme: HilitNavigationBar.Theme = .light,
        background: HilitNavigationBar.Background = .transparent,
        onClose: (() -> Void)? = nil
    ) -> some View {
        #if DEBUG
        assert(!(theme == .dark && trailing != nil),
               "HilitNavigationBar: 다크 바의 trailing 시안이 없다 — 필요하면 디자이너 확인 후 추가.")
        #endif
        return safeAreaInset(edge: .top, spacing: 0) {
            PresentedNavigationBar(title: title, trailing: trailing, theme: theme, onClose: onClose)
                .background {
                    if background == .filled {
                        theme.fillColor
                    }
                }
        }
    }
}

private struct HilitNavigationBarModifier: ViewModifier {
    enum Bar {
        case standard(title: String?, trailing: HilitNavigationBar.Trailing?, onClose: (() -> Void)?)
        case logo(onProfile: (() -> Void)?)
    }

    let bar: Bar
    let theme: HilitNavigationBar.Theme
    let background: HilitNavigationBar.Background
    let allowsSwipeBack: Bool

    /// `onClose` 기본값용 — 스택에 있으면 pop, present 됐으면 dismiss 를 SwiftUI 가 자동 분기.
    /// 어느 쪽이든 리듀서에는 `popFrom(id:)`/`PresentationAction.dismiss` 액션으로 도착한다(우회 아님).
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .toolbarBackground(background == .filled ? .visible : .hidden, for: .navigationBar)
            .toolbarBackground(theme.fillColor, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .background {
                SwipeBackPolicy(allows: allowsSwipeBack)
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        switch bar {
        case let .standard(title, trailing, onClose):
            ToolbarItem(placement: .topBarLeading) {
                HilitNavigationBarSlot.icon(theme.closeIcon, action: onClose ?? { dismiss() })
            }
            if let title {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .dsTypography(.sub7)
                        .foregroundStyle(theme.titleColor)
                        .lineLimit(1)
                }
            }
            if let trailing {
                ToolbarItem(placement: .topBarTrailing) {
                    HilitNavigationBarSlot.trailing(trailing)
                }
            }
        case let .logo(onProfile):
            ToolbarItem(placement: .topBarLeading) {
                Image.Logo.hilit
                    .resizable()
                    .scaledToFit()
                    .frame(width: 57, height: 24)
            }
            if let onProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    HilitNavigationBarSlot.icon(Image.Profile.default, action: onProfile)
                }
            }
        }
    }
}

// MARK: - present 화면용 수동 바

/// 스택 밖에서 시스템 바를 흉내 내는 44pt 바 — 레이아웃은 시안 실측
/// (총 44 = 슬롯 26 + 상하 9 · px20 · gap 6 · 아이콘 슬롯 폭 40 고정).
private struct PresentedNavigationBar: View {
    let title: String?
    let trailing: HilitNavigationBar.Trailing?
    let theme: HilitNavigationBar.Theme
    let onClose: (() -> Void)?

    /// `onClose` 기본값용 — present 된 화면이므로 dismiss.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 6) {
            HilitNavigationBarSlot.icon(theme.closeIcon, action: onClose ?? { dismiss() })
                .frame(width: 40, alignment: .leading)
            centerTitle
            trailingSlot
        }
        .frame(height: 44)
        .padding(.horizontal, .ds(.p20))
    }

    @ViewBuilder
    private var centerTitle: some View {
        if let title {
            Text(title)
                .dsTypography(.sub7)
                .foregroundStyle(theme.titleColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        } else {
            Spacer(minLength: 0)
        }
    }

    /// 아이콘 슬롯은 폭 40 고정(비어도 유지 — 타이틀 중앙 보존), 텍스트 버튼만 내용 폭(시안 hug).
    @ViewBuilder
    private var trailingSlot: some View {
        switch trailing {
        case let .plus(action):
            HilitNavigationBarSlot.icon(Image.Plus.default24, action: action)
                .frame(width: 40, alignment: .trailing)
        case let .text(label, action):
            HilitNavigationBarSlot.text(label, action: action)
        case nil:
            Color.clear.frame(width: 40)
        }
    }
}

// MARK: - 슬롯 렌더 공용부

/// 시스템 toolbar 경로(push)와 수동 바 경로(present)가 같은 룩을 공유하는 지점 —
/// 슬롯 스타일을 바꿀 땐 여기만 고친다.
private enum HilitNavigationBarSlot {
    static func icon(_ image: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }

    /// 텍스트 버튼은 시안의 button-mini 그대로(body5·g400·p8/p4 히트 영역).
    static func text(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .dsTypography(.body5)
                .foregroundStyle(Color.GrayScale.g400)
                .padding(.horizontal, .ds(.p8))
                .padding(.vertical, .ds(.p4))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    static func trailing(_ trailing: HilitNavigationBar.Trailing) -> some View {
        switch trailing {
        case let .plus(action):
            icon(Image.Plus.default24, action: action)
        case let .text(label, action):
            text(label, action: action)
        }
    }
}

// MARK: - Previews

#Preview("표준 — X만 / X+플러스 / X+텍스트") {
    VStack(spacing: 0) {
        NavigationStack {
            Color.clear.hilitNavigationBar("타이틀", background: .filled, onClose: {})
        }
        NavigationStack {
            Color.clear.hilitNavigationBar("타이틀", trailing: .plus {}, background: .filled, onClose: {})
        }
        NavigationStack {
            Color.clear.hilitNavigationBar("타이틀", trailing: .text("버튼") {}, background: .filled, onClose: {})
        }
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
    NavigationStack {
        Color.HilitBlack.b800
            .ignoresSafeArea()
            .hilitNavigationBar("타이틀", theme: .dark, background: .filled, onClose: {})
    }
}

#Preview("logo — 워드마크·프로필") {
    NavigationStack {
        Color.clear.hilitLogoNavigationBar(background: .filled, onProfile: {})
    }
}

#Preview("presented — 스택 밖 수동 바") {
    Text("fullScreenCover 단독 화면 (NavigationStack 없음)")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hilitPresentedNavigationBar("타이틀", trailing: .text("버튼") {}, background: .filled, onClose: {})
}

#Preview("배경 — filled vs transparent (스크롤 통과 대비)") {
    HStack(spacing: 0) {
        NavigationStack {
            ScrollView {
                VStack { ForEach(0..<30) { Text("콘텐츠 \($0)").frame(maxWidth: .infinity) } }
            }
            .hilitNavigationBar("filled", background: .filled, onClose: {})
        }

        NavigationStack {
            ScrollView {
                VStack { ForEach(0..<30) { Text("콘텐츠 \($0)").frame(maxWidth: .infinity) } }
            }
            .hilitNavigationBar("transparent", onClose: {})
        }
    }
}
