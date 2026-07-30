//
//  SplashView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import SharedDesignSystemInterface
import SwiftUI

/// Splash(SP) — 앱 실행 시 자동 로그인 판정 동안 표시되는 정적 화면.
/// 판정 로직은 AppFeature 루트 게이트 몫(`authClient.isAuthenticated`) — 이 뷰는 상태가 없다.
/// Figma 시안 존재 — 수령 시 로고·배경 교체. TODO: 최소 노출 시간 연출은 정책 확정 시.
public struct SplashView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.BlackWhite.white.ignoresSafeArea()
            Text("hilit")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.HilitBlack.b800)
        }
    }
}

#Preview("스플래시") {
    SplashView()
}
