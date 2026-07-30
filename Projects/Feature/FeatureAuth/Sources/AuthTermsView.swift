//
//  AuthTermsView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «AuthTerms» — 시안 수령 전 골격. 체크 로직·제출 활성은 확정 정책대로 실동작.
// 전문 바텀시트는 DS `.hilitBottomSheet` 껍데기 사용 — 시트 판은 여기서 그린다.
@ViewAction(for: AuthTermsFeature.self)
public struct AuthTermsView: View {
    @Bindable public var store: StoreOf<AuthTermsFeature>

    public init(store: StoreOf<AuthTermsFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                Text("서비스 이용을 위해\n동의가 필요해요")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)

                allConsentRow

                VStack(spacing: 16) {
                    ForEach(AuthTermsFeature.ConsentItem.allCases) { item in
                        consentRow(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer(minLength: 0)

            // 필수 5종 모두 체크 시에만 활성 — 일부 체크는 비활성일 뿐 별도 경고 없음(PRD).
            ButtonLarge("동의하고 시작하기", .bottom) { send(.userTappedAgree) }
                .disabled(!store.isSubmitEnabled)
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
        .hilitBottomSheet(
            item: store.presentedDocument,
            onDimTap: { send(.userDismissedDocument) }
        ) { item in
            documentSheet(item)
        }
    }

    private var allConsentRow: some View {
        Toggle(isOn: allConsentBinding) {
            Text("전체 동의")
                .dsTypography(.sub7)
                .foregroundStyle(Color.GrayScale.g800)
        }
        .toggleStyle(.hilitCheckbox)
    }

    private func consentRow(_ item: AuthTermsFeature.ConsentItem) -> some View {
        HStack(spacing: 0) {
            Toggle(isOn: consentBinding(item)) {
                Text(item.title)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g800)
            }
            .toggleStyle(.hilitCheckbox)

            Spacer(minLength: 8)

            if item.hasDocument {
                Button("보기") { send(.userTappedDocument(item)) }
                    .buttonStyle(.miniSub(.white))
            }
        }
    }

    /// 전문 바텀시트 판 — `.hilitBottomSheet` 는 딤·전환만 주는 껍데기라 판(배경·코너·패딩)은 호출부 몫.
    /// TODO(S-2): 전문 텍스트 — 국외 이전은 벤더 답변 대기, 나머지 4종도 법무 확정본으로 교체.
    private func documentSheet(_ item: AuthTermsFeature.ConsentItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.title)
                .dsTypography(.sub7)
                .foregroundStyle(Color.GrayScale.g800)

            ScrollView {
                Text("전문 준비 중입니다.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 320)

            ButtonLarge("확인", .modal) { send(.userDismissedDocument) }
        }
        .padding(.ds(.p20))
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(Color.BlackWhite.white)
                .ignoresSafeArea(edges: .bottom)   // 판만 홈 인디케이터 아래까지
        }
    }

    // MARK: - Toggle 바인딩 (상태는 리듀서 소유 — set 은 view 액션으로만)

    private var allConsentBinding: Binding<Bool> {
        Binding(
            get: { store.isAllChecked },
            set: { _ in send(.userToggledAllConsent) }
        )
    }

    private func consentBinding(_ item: AuthTermsFeature.ConsentItem) -> Binding<Bool> {
        Binding(
            get: { store.checked.contains(item) },
            set: { _ in send(.userToggledConsent(item)) }
        )
    }
}

#Preview("약관 동의 — 기본(버튼 비활성)") {
    AuthTermsView(
        store: Store(initialState: AuthTermsFeature.State()) {
            AuthTermsFeature()
        }
    )
}

#Preview("약관 동의 — 필수 충족(버튼 활성)") {
    var state = AuthTermsFeature.State()
    state.checked = Set(AuthTermsFeature.ConsentItem.allCases)
    return AuthTermsView(
        store: Store(initialState: state) {
            AuthTermsFeature()
        }
    )
}
