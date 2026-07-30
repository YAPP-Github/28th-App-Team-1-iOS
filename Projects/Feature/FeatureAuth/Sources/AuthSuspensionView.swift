//
//  AuthSuspensionView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «AuthSuspension» — 시안 수령 전 골격(전면 화면 가정 — 모달 여부 디자인 확정 대기).
// 사유 문구에 NETWORK_DISCONNECT 등 내부 용어를 노출하지 않는다(용어 표준 — PRD Part7).
@ViewAction(for: AuthSuspensionFeature.self)
public struct AuthSuspensionView: View {
    @Bindable public var store: StoreOf<AuthSuspensionFeature>

    public init(store: StoreOf<AuthSuspensionFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("면접 이용이 제한되었어요")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("비정상적인 이용 패턴이 반복 확인되어\n면접 시작이 제한되었어요")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
                    .multilineTextAlignment(.center)

                Button("문의: \(AuthSuspensionFeature.supportEmail)") {
                    send(.userTappedContactSupport)
                }
                .buttonStyle(.miniSub(.white))
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)

            Spacer()

            ButtonLarge("홈으로 돌아가기", .bottom) { send(.userTappedGoHome) }
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
    }
}

#Preview("이용 제한 안내") {
    AuthSuspensionView(
        store: Store(initialState: AuthSuspensionFeature.State()) {
            AuthSuspensionFeature()
        }
    )
}
