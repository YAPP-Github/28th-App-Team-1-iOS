//
//  AuthTermsView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Create_Account_Terms of Service» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3768-16521
//        «Create_Account_Terms of Service_Detail»(전문 바텀시트)
//        https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=477-6308 — 공유용 파일의 개정본이
//        전문 시트의 기준이다(구 ZG7F…?node-id=3768-17124 대비 시트 안 CTA 제거).
//        두 노드는 별개 화면이 아니라 같은 화면의 기본/시트 상태다 — 시트는 DS `.hilitBottomSheet`
//        오버레이에 본문만 얹는다(딤·자리·드래그·그래버·모서리 0 은 DS 몫).

import ComposableArchitecture
import DomainConsentInterface
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
        /// 시트가 처음 서는 자리 (시안 662 / 812) — 위로 끌면 화면을 꽉 채운다.
        static let sheetHeightRatio: CGFloat = 662.0 / 812.0
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
        // 시안 높이(662/812)로 열리고, 그래버를 끌어 전체 높이까지 늘렸다 줄일 수 있다 — 자리 2개.
        .hilitBottomSheet(
            item: store.presentedDocument,
            detents: [Metric.sheetHeightRatio, 1],
            onDismiss: { send(.userDismissedDocument) },
            content: { item in documentSheet(item) }
        )
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear { send(.onAppear) }
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

                // 항목은 서버(`pending`)가 준다 — 최초는 필수 5종 전체, 재동의는 바뀐 항목만.
                if let items = store.items {
                    VStack(spacing: .ds(.p20)) {
                        ForEach(items, id: \.code) { item in
                            consentRow(item)
                        }
                    }
                } else if store.loadFailed {
                    loadFailure
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

    /// 항목 조회 실패 — 목록 자리에 재시도만 둔다(약관 없이 진행시킬 수는 없어서).
    private var loadFailure: some View {
        VStack(spacing: .ds(.p12)) {
            Text("약관을 불러오지 못했어요.")
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g500)
            Button("다시 시도") { send(.userTappedRetryLoad) }
                .buttonStyle(.miniSub(.none))
        }
        .frame(maxWidth: .infinity)
    }

    private func consentRow(_ item: ConsentItem) -> some View {
        HStack(spacing: .ds(.p8)) {
            Toggle(isOn: consentBinding(item)) {
                Text(item.rowTitle)
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

    // MARK: - 전문 바텀시트 (node 477:6341)

    /// 전문 시트 본문 — 딤·자리·드래그·그래버·판 배경(흰색 기본)·모서리 0 은 DS 시트가 준다.
    /// 여기는 제목 줄과 스크롤 본문만 그리고, 높이는 선 자리를 그대로 채운다(고정 frame 없음).
    /// 본문은 서버 마크다운(`ConsentClient.document`) — 조회 중엔 빈 화면이다.
    ///
    /// **시트 안에 CTA 가 없다** (개정 시안 477:6341 — 하단은 홈 인디케이터 띠뿐).
    /// 나가는 경로는 아래로 끌기·딤 탭이고, 동의 제출은 시트를 닫은 뒤 화면 CTA 로 한다.
    private func documentSheet(_ item: ConsentItem) -> some View {
        VStack(spacing: 0) {
            Text(item.documentTitle)
                .dsTypography(.sub7)
                .foregroundStyle(Color.HilitBlack.b800)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .ds(.p20))
                .padding(.vertical, .ds(.p10))

            ScrollView {
                documentBody(store.documentContent ?? "")
                    // 마지막 줄이 홈 인디케이터에 붙지 않게 — 시안 하단 흰 띠(21) 자리.
                    .padding(.bottom, .ds(.p20))
            }
            .padding(.horizontal, .ds(.p20))
            .padding(.top, .ds(.p16))
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 전문 본문 — 서버 마크다운을 블록으로 갈라 그린다.
    /// `Text` 의 기본 마크다운은 **인라인만**(굵게·기울임·링크) 알아서 «### 제1조» 같은 헤딩이
    /// 원문 그대로 남는다. 그 한 겹(헤딩 ↔ 문단)만 우리가 파고, 인라인은 계속 `Text` 에 맡긴다.
    private func documentBody(_ markdown: String) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p12)) {
            ForEach(Array(DocumentBlock.parse(markdown).enumerated()), id: \.offset) { index, block in
                switch block {
                case let .heading(level, text):
                    Text(LocalizedStringKey(text))
                        .dsTypography(Self.headingTypography(level))
                        .foregroundStyle(Color.HilitBlack.b800)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // 조문 사이를 벌린다 — 문단 간격(12)에 얹어 첫 블록만 뺀다.
                        .padding(.top, index == 0 ? 0 : .ds(.p12))

                case let .paragraph(text):
                    Text(LocalizedStringKey(text))
                        .dsTypography(.body4)
                        .foregroundStyle(Color.GrayScale.g800)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// 헤딩 깊이 → 타이포. 본문(body4=16r)보다 한 단씩 굵고 크게만 잡으면 되는 얕은 문서다.
    private static func headingTypography(_ level: Int) -> DSTypography {
        switch level {
        case 1: .sub4
        case 2: .sub7
        default: .body2
        }
    }

    // MARK: - Toggle 바인딩 (상태는 리듀서 소유 — set 은 view 액션으로만)

    private var allConsentBinding: Binding<Bool> {
        Binding(
            get: { store.isAllChecked },
            set: { _ in send(.userToggledAllConsent) }
        )
    }

    private func consentBinding(_ item: ConsentItem) -> Binding<Bool> {
        Binding(
            get: { store.checked.contains(item.code) },
            set: { _ in send(.userToggledConsent(item)) }
        )
    }
}

// MARK: - Previews

/// 프리뷰 항목 — 실제 목록은 서버(`pending`)가 준다. previewValue 와 같은 필수 5종.
private let previewItems = [
    ConsentItem(code: "AGE_OVER_14", label: "만 14세 이상", isRequired: true, version: 1, hasDocument: false),
    ConsentItem(code: "TERMS_OF_SERVICE", label: "서비스 이용약관", isRequired: true, version: 1, hasDocument: true),
    ConsentItem(code: "PERSONAL_INFO_COLLECTION", label: "개인정보 수집·이용", isRequired: true, version: 1, hasDocument: true),
    ConsentItem(code: "INTERVIEW_RECORDING", label: "면접 영상·음성 촬영·저장", isRequired: true, version: 1, hasDocument: true),
    ConsentItem(code: "OVERSEAS_TRANSFER", label: "개인정보 국외 이전", isRequired: true, version: 1, hasDocument: true)
]

#Preview("약관 동의 — 기본(버튼 비활성)") {
    AuthTermsView(
        store: Store(initialState: AuthTermsFeature.State(items: previewItems)) {
            AuthTermsFeature()
        }
    )
}

#Preview("약관 동의 — 필수 충족(버튼 활성)") {
    var state = AuthTermsFeature.State(items: previewItems)
    state.checked = Set(previewItems.map(\.code))
    return AuthTermsView(
        store: Store(initialState: state) {
            AuthTermsFeature()
        }
    )
}

#Preview("약관 동의 — 전문 바텀시트") {
    var state = AuthTermsFeature.State(items: previewItems)
    state.checked = Set(previewItems.map(\.code))
    state.presentedDocument = previewItems[1]
    state.documentContent = "제1조 (목적)\n이 약관은 프리뷰용 본문입니다."
    return AuthTermsView(
        store: Store(initialState: state) {
            AuthTermsFeature()
        }
    )
}

#Preview("약관 동의 — 조회 실패") {
    var state = AuthTermsFeature.State()
    state.loadFailed = true
    return AuthTermsView(
        store: Store(initialState: state) {
            AuthTermsFeature()
        }
    )
}
