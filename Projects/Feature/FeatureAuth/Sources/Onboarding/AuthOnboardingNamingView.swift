//
//  AuthOnboardingNamingView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Onboarding_Naming» 빈 상태     https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3877-5381
//        «Onboarding_Naming» 입력된 상태 https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3877-11635

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 가입 온보딩 1 — 이름 입력. 시안의 두 상태(빈/입력됨)는 파라미터가 아니라 `store.name` 에서 파생된다
/// (`NameField` 가 `text.isEmpty` 로 밑줄·글자색을, `ButtonLarge` 가 `disabled` 로 판 색을 정한다).
@ViewAction(for: AuthOnboardingNamingFeature.self)
public struct AuthOnboardingNamingView: View {
    @Bindable public var store: StoreOf<AuthOnboardingNamingFeature>

    public init(store: StoreOf<AuthOnboardingNamingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressBar
                // 내비바와 프로그레스 사이 간격 — 시안 top-bar/progress bar 사이 gap 8.
                .padding(.top, .ds(.p8))

            TitleBox(["반가워요!", "이름을 입력해주세요"], tag: "필수")
                .padding(.top, .ds(.p20))
                .padding(.horizontal, .ds(.p20))

            nameField

            Spacer(minLength: 0)

            ButtonLarge("다음", .bottom) { send(.userTappedContinue) }
                .disabled(!store.isContinueEnabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
        .dismissesKeyboardOnTap()
    }

    /// 가입 온보딩 진행 위치 — 조각 수는 `totalSteps`, 켜지는 범위는 `step` 에서 파생.
    // @ds(component): progress bar 3877:11573 — 조각 h4 가 가로를 등분한다. DS `DashIndicator` 는
    //                 조각이 20×4 고정폭이라 못 쓴다 (온보딩 4화면 공용 승격 후보)
    // @ds(spacing): 2 — 조각 사이 간격 (spacing 토큰은 4~24 뿐)
    private var progressBar: some View {
        HStack(spacing: 2) {
            ForEach(1...max(store.totalSteps, 1), id: \.self) { step in
                Rectangle()
                    .fill(step <= store.step ? Color.HilitBlack.b800 : Color.GrayScale.g50)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p4))
    }

    /// 이름 입력란 — 폭은 내용 hug 라 가운데 정렬은 호출부(`frame(maxWidth:)`) 몫.
    // @ds(layout): 149 — 머리글과 입력란 사이. 시안은 name-field 를 y=367 에 절대 배치하는데,
    //              머리글 아래 여백(=125)에 비어 있는 서브 타이틀 슬롯 24 를 흡수시킨 값이다
    private var nameField: some View {
        NameField("이름을 알려주세요", text: $store.name)
            .frame(maxWidth: .infinity)
            .padding(.top, 149)
            .onSubmit { send(.userTappedContinue) }
    }
}

#Preview("이름 입력 — 빈 상태") {
    AuthOnboardingNamingView(
        store: Store(initialState: AuthOnboardingNamingFeature.State()) {
            AuthOnboardingNamingFeature()
        }
    )
}

#Preview("이름 입력 — 입력됨") {
    var state = AuthOnboardingNamingFeature.State()
    state.name = "박민"
    return AuthOnboardingNamingView(
        store: Store(initialState: state) {
            AuthOnboardingNamingFeature()
        }
    )
}
