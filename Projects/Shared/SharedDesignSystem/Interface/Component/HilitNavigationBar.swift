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
/// Figma 3변형을 슬롯 조합으로 옮겼다:
/// - **icon**: 좌 아이콘 + 중앙 타이틀 + 우 아이콘 — `HilitNavigationBar("타이틀", leading: …, trailing: .icon(…))`
/// - **text**: 우측이 텍스트 버튼 — `trailing: .text("버튼") { … }`
/// - **logo**: Hilit 워드마크 + 우측 아이콘 — `HilitNavigationBar.logo(trailing: …)`
///
/// 시안의 show 토글은 슬롯에 `nil` 을 넘기는 것과 같다. 아이콘은 인스턴스 스왑 슬롯이라
/// `Image` 토큰을 직접 받는다(기본값 없음 — 닫기인지 뒤로인지는 화면이 안다).
/// 배경은 그리지 않는다 — 화면 배경 위에 얹는 투명 바라서, 다크 화면(`Cancel.white24`)에서도 그대로 쓴다.
///
/// `NavigationStack` push 화면에서는 시스템 백버튼과 겹치지 않게
/// `.navigationBarBackButtonHidden(true)` 를 화면 쪽에서 함께 건다 (기존 관행).
public struct HilitNavigationBar: View {
    /// 좌·우 슬롯 내용물. `.text` 는 Figma 상 trailing 전용 (leading 에 넣으면 DEBUG assert).
    public enum Accessory {
        case icon(Image, action: () -> Void)
        case text(String, action: () -> Void)
    }

    private enum Center {
        case title(String?)
        case logo
    }

    private let center: Center
    private let leading: Accessory?
    private let trailing: Accessory?

    /// icon·text 변형 — 중앙 타이틀(없으면 빈 중앙), 좌·우 슬롯 옵션.
    public init(
        _ title: String? = nil,
        leading: Accessory? = nil,
        trailing: Accessory? = nil
    ) {
        self.center = .title(title)
        self.leading = leading
        self.trailing = trailing
        #if DEBUG
        if case .text = leading {
            assertionFailure("HilitNavigationBar: 텍스트 버튼은 trailing 전용 (Figma text 변형)")
        }
        #endif
    }

    private init(center: Center, leading: Accessory?, trailing: Accessory?) {
        self.center = center
        self.leading = leading
        self.trailing = trailing
    }

    /// logo 변형 — Hilit 워드마크 좌측 고정, 우측 아이콘 슬롯 옵션 (Figma 는 profile).
    public static func logo(trailing: Accessory? = nil) -> HilitNavigationBar {
        HilitNavigationBar(center: .logo, leading: nil, trailing: trailing)
    }

    public var body: some View {
        HStack(spacing: 6) {
            switch center {
            case let .title(title):
                slotView(leading, alignment: .leading)
                centerTitle(title)
                slotView(trailing, alignment: .trailing)
            case .logo:
                Image.Logo.hilit
                    .resizable()
                    .scaledToFit()
                    .frame(width: 57, height: 24)
                Spacer(minLength: 0)
                slotView(trailing, alignment: .trailing)
            }
        }
        // 슬롯 26(아이콘 24 + 상하 1) + 상하 p14 = 총 54 (Figma 실측).
        .frame(height: 26)
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p14))
    }

    @ViewBuilder
    private func centerTitle(_ title: String?) -> some View {
        if let title {
            Text(title)
                .dsTypography(.sub7)
                .foregroundStyle(Color.HilitBlack.b800)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        } else {
            Spacer(minLength: 0)
        }
    }

    /// 아이콘 슬롯은 폭 40 고정(시안 leading 컨테이너 값) — 비어 있어도 유지해 타이틀 중앙을 지킨다.
    /// 텍스트 버튼(trailing 전용)만 내용 폭 — 시안도 hug 라 타이틀이 살짝 좌측으로 치우친다.
    @ViewBuilder
    private func slotView(_ accessory: Accessory?, alignment: Alignment) -> some View {
        switch accessory {
        case let .icon(image, action):
            Button(action: action) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .frame(width: 40, alignment: alignment)
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
    /// 화면은 바 내용(타이틀·슬롯)만 선언하고, 배관(`navigationBarBackButtonHidden`·
    /// `toolbar(.hidden)`·`safeAreaInset`)은 여기가 소유한다 — 화면마다 깜빡할 일 없음.
    ///
    /// `background` 는 스크롤 콘텐츠가 바 아래로 지나갈 때 비치지 않게 바 뒤에 깐다 —
    /// 화면 배경색과 같은 토큰을 넘긴다(다크 화면이면 `Color.HilitBlack.b800` + white 아이콘).
    ///
    /// `navigationBarBackButtonHidden` 이 끄는 엣지 스와이프백은
    /// `UINavigationController+SwipeBack.swift` 가 전역 복구한다.
    /// 뒤로가기가 필요한 push 화면은 leading 에 `Image.Left.*` 버튼도 함께 놓을 것(보이는 어포던스).
    ///
    /// `allowsSwipeBack: false` — 스와이프 pop 을 이 화면에서만 끈다.
    /// 스와이프는 버튼과 달리 화면의 «나가기 전 로직»(저장·확인)을 안 태우므로,
    /// pop 이 리듀서 로직과 묶인 플로우(온보딩 스텝 등)는 끄고 버튼으로만 뒤로 간다.
    func hilitNavigationBar(
        _ title: String? = nil,
        leading: HilitNavigationBar.Accessory? = nil,
        trailing: HilitNavigationBar.Accessory? = nil,
        background: Color = Color.BlackWhite.white,
        allowsSwipeBack: Bool = true
    ) -> some View {
        attachHilitNavigationBar(
            HilitNavigationBar(title, leading: leading, trailing: trailing),
            background: background,
            allowsSwipeBack: allowsSwipeBack
        )
    }

    /// logo 변형(Hilit 워드마크) 부착 — 홈처럼 브랜드 바를 쓰는 루트 화면용.
    func hilitLogoNavigationBar(
        trailing: HilitNavigationBar.Accessory? = nil,
        background: Color = Color.BlackWhite.white
    ) -> some View {
        // logo 변형은 루트 전용 — 루트는 pop 대상이 없어 스와이프백 스위치가 무의미.
        attachHilitNavigationBar(.logo(trailing: trailing), background: background, allowsSwipeBack: true)
    }

    private func attachHilitNavigationBar(
        _ bar: HilitNavigationBar,
        background: Color,
        allowsSwipeBack: Bool
    ) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            bar.background(background)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background {
            if !allowsSwipeBack {
                SwipeBackDisabler()
            }
        }
    }
}

// MARK: - Previews

#Preview("icon — 닫기·추가") {
    VStack(spacing: 0) {
        HilitNavigationBar(
            "타이틀",
            leading: .icon(Image.Cancel.default24) {},
            trailing: .icon(Image.Plus.default24) {}
        )
        Divider()
        Spacer()
    }
}

#Preview("text — 우측 텍스트 버튼") {
    VStack(spacing: 0) {
        HilitNavigationBar(
            "타이틀",
            leading: .icon(Image.Cancel.default24) {},
            trailing: .text("버튼") {}
        )
        Divider()
        Spacer()
    }
}

#Preview("logo — 워드마크·프로필") {
    VStack(spacing: 0) {
        HilitNavigationBar.logo(trailing: .icon(Image.Profile.default) {})
        Divider()
        Spacer()
    }
}

#Preview("슬롯 생략 — 닫기만 / 타이틀만") {
    VStack(spacing: 0) {
        HilitNavigationBar(leading: .icon(Image.Cancel.default24) {})
        HilitNavigationBar("타이틀")
        Divider()
        Spacer()
    }
}
