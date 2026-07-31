//
//  AuthTermsView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Create_Account_Terms of Service» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3768-16521
//        «Create_Account_Terms of Service_Detail»(전문 바텀시트) …?node-id=3768-17124
//        두 노드는 별개 화면이 아니라 같은 화면의 기본/오버레이 상태다 — 시트는 DS `.hilitBottomSheet`
//        껍데기 위에 판만 그린다(딤·바닥 정렬·슬라이드는 DS 몫).

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

@ViewAction(for: AuthTermsFeature.self)
public struct AuthTermsView: View {
    /// 시안 수치 중 토큰 스케일에 없는 값 — 사용처마다 `@ds` 태그로 근거를 남긴다.
    private enum Metric {
        /// 내비바 아래 첫 콘텐츠 여백 (시안 절대 top 113 − 상태바 43 − top-bar 44).
        static let contentTop: CGFloat = 26
        /// 타이틀 ↔ 동의 목록.
        static let titleToConsent: CGFloat = 54
        /// 전체동의 ↔ 구분선 ↔ 항목 목록.
        static let consentSection: CGFloat = 34
        /// 시트 판 높이 비율 (시안 662 / 812).
        static let sheetHeightRatio: CGFloat = 662.0 / 812.0
        static let grabberWidth: CGFloat = 60
        static let grabberHeight: CGFloat = 5
        static let grabberRowHeight: CGFloat = 20
    }

    @Bindable public var store: StoreOf<AuthTermsFeature>

    public init(store: StoreOf<AuthTermsFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            consentColumn

            Spacer(minLength: 0)

            // 필수 5종 모두 체크 시에만 활성 — 일부 체크는 비활성일 뿐 별도 경고 없음(PRD).
            // 시안 기본 상태의 color=disabled(g50 판 + g300 라벨)가 이 비활성 룩이다.
            ButtonLarge("동의하고 시작하기", .bottom) { send(.userTappedAgree) }
                .disabled(!store.isSubmitEnabled)
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
        .hilitBottomSheet(
            item: store.presentedDocument,
            onDimTap: { send(.userDismissedDocument) },
            content: { item in documentSheet(item) }
        )
    }

    // MARK: - 본문 (node 3768:16905)

    private var consentColumn: some View {
        // @ds(spacing): 54 — 타이틀 ↔ 동의 목록 (spacing 토큰은 4~24 뿐)
        VStack(alignment: .leading, spacing: Metric.titleToConsent) {
            Text("Hilit 서비스 약관에\n동의해주세요")
                .dsTypography(.head4)
                .foregroundStyle(Color.GrayScale.g900)
                .frame(maxWidth: .infinity, alignment: .leading)

            // @ds(spacing): 34 — 전체동의·구분선·항목 목록 사이 (spacing 토큰은 4~24 뿐)
            VStack(alignment: .leading, spacing: Metric.consentSection) {
                allConsentRow
                divider

                VStack(spacing: .ds(.p20)) {
                    ForEach(AuthTermsFeature.ConsentItem.allCases) { item in
                        consentRow(item)
                    }
                }
            }
        }
        .padding(.horizontal, .ds(.p20))
        // @ds(spacing): 26 — 내비바 아래 첫 콘텐츠 (spacing 토큰은 4~24 뿐)
        .padding(.top, Metric.contentTop)
    }

    /// «모두 동의합니다.» — 하나라도 빠지면 전부 켜고, 전부 켜져 있으면 전부 끈다(판단은 리듀서).
    private var allConsentRow: some View {
        Toggle(isOn: allConsentBinding) {
            Text("모두 동의합니다.")
                .dsTypography(.sub7)
                .foregroundStyle(Color.GrayScale.g900)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.hilitCheckbox)
    }

    // @ds(component): 구분선 1pt — divider 원본 3165:14357 (stroke #31333B). 공용 컴포넌트 없음.
    //                 색·두께는 g800·outline-s 토큰으로 흡수했으니 치환 대상은 «컴포넌트» 뿐이다.
    private var divider: some View {
        Rectangle()
            .fill(Color.GrayScale.g800)
            .frame(height: .ds(.small))
    }

    private func consentRow(_ item: AuthTermsFeature.ConsentItem) -> some View {
        HStack(spacing: .ds(.p8)) {
            Toggle(isOn: consentBinding(item)) {
                Text(item.title)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g900)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.hilitCheckbox)

            if item.hasDocument {
                Button("보기") { send(.userTappedDocument(item)) }
                    .buttonStyle(.miniSub(.none))
            }
        }
    }

    // MARK: - 전문 바텀시트 (node 3768:17192)

    /// 전문 시트 판 — `.hilitBottomSheet` 가 딤·바닥 정렬·전환만 주는 껍데기라 판은 호출부 몫.
    /// 시안 판은 **상단 코너 0**(DS 전반의 «모서리 0» 과 같은 결) + 흰 배경 + 높이 662.
    /// TODO(S-2): 전문 텍스트 — 국외 이전은 벤더 답변 대기, 나머지 4종도 법무 확정본으로 교체.
    private func documentSheet(_ item: AuthTermsFeature.ConsentItem) -> some View {
        VStack(spacing: 0) {
            grabber

            Text(item.documentTitle)
                .dsTypography(.sub7)
                .foregroundStyle(Color.HilitBlack.b800)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .ds(.p20))
                .padding(.vertical, .ds(.p10))

            ScrollView {
                Text("전문 준비 중입니다.")
                    .dsTypography(.body4)
                    .foregroundStyle(Color.GrayScale.g800)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, .ds(.p20))
            .padding(.top, .ds(.p16))
            .frame(maxHeight: .infinity)

            // 시안(3768:17215)이 시트 안에 화면 CTA 를 그대로 넣었고, 동작도 같다 —
            // 필수 5종 전부 체크 시 활성, 누르면 다음 화면(이름 입력)으로 (사용자 확인 2026-07-31).
            // «이 항목만 동의하고 시트 닫기» 가 아니므로 별도 액션을 두지 않는다.
            ButtonLarge("동의하고 시작하기", .bottom) { send(.userTappedAgree) }
                .disabled(!store.isSubmitEnabled)
        }
        // @ds(layout): 662/812 (81.5%) — 시트 판 높이. 시안이 812pt 기기 고정값이라 비율로 옮겼다
        .containerRelativeFrame(.vertical) { height, _ in height * Metric.sheetHeightRatio }
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Color.BlackWhite.white)
                .ignoresSafeArea(edges: .bottom)   // 판만 홈 인디케이터 아래까지
        }
    }

    // @ds(component): 시트 그래버 — 60×5 g400 바(모서리 0) + 행 높이 20. 공용 컴포넌트 없음
    private var grabber: some View {
        Rectangle()
            .fill(Color.GrayScale.g400)
            .frame(width: Metric.grabberWidth, height: Metric.grabberHeight)
            .frame(maxWidth: .infinity)
            .frame(height: Metric.grabberRowHeight)
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

#Preview("약관 동의 — 전문 바텀시트") {
    var state = AuthTermsFeature.State()
    state.checked = Set(AuthTermsFeature.ConsentItem.allCases)
    state.presentedDocument = .termsOfService
    return AuthTermsView(
        store: Store(initialState: state) {
            AuthTermsFeature()
        }
    )
}
