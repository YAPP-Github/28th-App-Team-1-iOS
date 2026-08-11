//
//  AuthOnboardingRegisterView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Onboarding_RegisterDone» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-14643

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 가입 온보딩 4 — 등록 완료. 성공 일러스트 + 완료 문구 + 시작 CTA.
/// 종결 화면이라 프로그레스·뒤로가기 없음(내비바도 없음 — 이탈 경로를 두지 않는다).
@ViewAction(for: AuthOnboardingRegisterFeature.self)
public struct AuthOnboardingRegisterView: View {
    @Bindable public var store: StoreOf<AuthOnboardingRegisterFeature>

    public init(store: StoreOf<AuthOnboardingRegisterFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 시안은 그룹을 y=268(정중앙보다 28 위)에 절대 배치하지만, 전면 안내 화면은
            // 정중앙으로 통일한다(사용자 결정 2026-07-31) — AuthSuspensionView 와 같은 규칙.
            Spacer(minLength: 0)

            completionMessage

            Spacer(minLength: 0)

            ButtonLarge("시작하기", .bottom) { send(.userTappedStart) }
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    /// 성공 일러스트 + 완료 문구 (시안 Frame 2147230616, 202×175).
    private var completionMessage: some View {
        VStack(spacing: .ds(.p20)) {
            // 100×100 그대로 — 크기별 별도 에셋이라 frame 으로 늘리지 않는다.
            Image.Img.success

            VStack(spacing: .ds(.p4)) {
                Text("등록이 완료됐어요!")
                    .dsTypography(.sub1)
                    .foregroundStyle(Color.HilitBlack.b800)

                Text("Hilit과 면접 여정을 시작해보세요")
                    .dsTypography(.body4)
                    .foregroundStyle(Color.GrayScale.g500)
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview("등록 완료") {
    AuthOnboardingRegisterView(
        store: Store(initialState: AuthOnboardingRegisterFeature.State(userName: "재원")) {
            AuthOnboardingRegisterFeature()
        }
    )
}
