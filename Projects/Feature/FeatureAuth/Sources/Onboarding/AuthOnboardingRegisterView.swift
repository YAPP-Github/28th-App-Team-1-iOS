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
            // @ds(layout): 시안 그룹 y=268 (375×812 절대배치, 상하 여백 224:280) → Spacer 균등 중앙(≈y=296).
            // 오토레이아웃이 없는 프레임이라 «약간 위쪽 중앙»이 의도로 보이고, 28pt 차는 비율 스페이서가
            // 필요해 보류했다 — 디자이너 확정 후 비율/고정 여백 중 하나로 교체.
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
