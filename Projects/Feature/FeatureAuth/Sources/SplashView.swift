//
//  SplashView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Splash» https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-14037

import SharedDesignSystemInterface
import SwiftUI

/// Splash(SP) — 앱 실행 시 자동 로그인 판정 동안 표시되는 정적 화면.
/// 판정 로직은 AppFeature 루트 게이트 몫(`authClient.isAuthenticated`) — 이 뷰는 상태가 없다.
///
/// 시안의 상태 바(9:41·안테나·배터리)와 홈 인디케이터는 iOS 시스템 크롬이라 그리지 않는다 —
/// 배경이 전면 흰색이라 `ignoresSafeArea` 만으로 시안과 같은 결과가 된다.
///
/// **CreateAccount 전환 시작 상태** — 로고는 움직이지 않는다. 시안 대조 결과 두 화면의 로고가
/// 같은 좌표·크기(x102 y320 · 171×72)라 소셜 로그인 버튼만 아래에서 올라온다.
/// 그래서 `matchedGeometryEffect` 도, `init` 에 namespace 파라미터도 필요 없다.
/// `logoSize`/`logoCenterOffsetY` 는 `AuthCreateAccountView` 가 실제로 읽어 픽셀 일치를 보장한다 —
/// **이름·값을 바꾸면 그쪽 로고가 함께 움직인다**(의도된 결합). 전환 코드는 CreateAccount 쪽 몫.
public struct SplashView: View {
    /// 시안 로고 크기 — 전환 시작 프레임.
    // @ds(icon): 171×72 → Image.Logo.hilit — 스플래시 워드마크. 토큰은 57×24 내비바 판이지만
    //   시안 벡터가 좌표까지 정확히 3배 동일(재드로잉 아님)이라 확대로 재현 가능
    static let logoSize = CGSize(width: 171, height: 72)

    /// 로고 중심의 화면 중심 대비 수직 오프셋 — 전환 시작 위치.
    // @ds(layout): -50 — 로고를 화면 중심보다 위로 띄운 값 (시안 375×812 기준 중심 y 356)
    static let logoCenterOffsetY: CGFloat = -50

    public init() {}

    public var body: some View {
        ZStack {
            Color.BlackWhite.white
            logoMark
        }
        .ignoresSafeArea()
    }

    /// hilit 워드마크 — 전환에서 움직이는 유일한 요소라 따로 떼어 둔다.
    private var logoMark: some View {
        Image.Logo.hilit
            .resizable()
            .scaledToFit()
            .frame(width: Self.logoSize.width, height: Self.logoSize.height)
            .offset(y: Self.logoCenterOffsetY)
    }
}

#Preview("스플래시") {
    SplashView()
}
