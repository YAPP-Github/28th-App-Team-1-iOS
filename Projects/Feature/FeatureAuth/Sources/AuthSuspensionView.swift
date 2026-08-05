//
//  AuthSuspensionView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma: «Account_Suspension Notice» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3768-17227
// 내비바 없는 전면 안내 화면 — 뒤로가기가 없다(면접 시작 게이트에서 차단된 상태라 되돌릴 대상이 없음).
// 사유 문구에 NETWORK_DISCONNECT 등 내부 용어를 노출하지 않는다(용어 표준 — PRD Part7).
@ViewAction(for: AuthSuspensionFeature.self)
public struct AuthSuspensionView: View {
    @Bindable public var store: StoreOf<AuthSuspensionFeature>

    public init(store: StoreOf<AuthSuspensionFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 시안은 안내 블록을 y=280(정중앙보다 24.5 위)에 절대 배치하지만,
            // 전면 안내 화면은 정중앙으로 통일한다(사용자 결정 2026-07-31) — 기기 폭·높이에 무관하게 같은 결.
            noticeBlock
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
    }

    // MARK: - 안내 블록

    /// 아이콘 + 타이틀 + 사유·문의 안내. 시안 Frame 2147230624 (gap 20 / 4 / 16).
    private var noticeBlock: some View {
        VStack(spacing: .ds(.p20)) {
            Image.Issue.error24

            VStack(spacing: .ds(.p4)) {
                Text("면접 이용이 제한되었어요")
                    .dsTypography(.sub1)
                    .foregroundStyle(Color.HilitBlack.b800)

                VStack(spacing: .ds(.p16)) {
                    Text("비정상적인 이용 패턴이 반복 확인되어 면접 시작이\n제한되었어요. 궁금한 점은 아래로 문의해주세요.")
                        .dsTypography(.body4)

                    Text("문의 : \(AuthSuspensionFeature.supportEmail)")
                        .dsTypography(.body4)
                }
                .foregroundStyle(Color.GrayScale.g500)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .ds(.p20))
    }

    // MARK: - 하단 바

    /// 하단 «메일 보내기 | 홈으로» 바 — 배경·구분선·등폭 배치·눌림은 `ButtonLarge(.bottom, tone: .dark)` 가 소유.
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("메일 보내기") { send(.userTappedContactSupport) }
        } trailing: {
            Button("홈으로") { send(.userTappedGoHome) }
        }
    }
}

#Preview("이용 제한 안내") {
    AuthSuspensionView(
        store: Store(initialState: AuthSuspensionFeature.State()) {
            AuthSuspensionFeature()
        }
    )
}
