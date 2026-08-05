//
//  OnboardingJDLinkView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «STEP 3_JD 링크 입력» (1609:8597) + 하위 상태(로딩 1716:5283 · 에러 1716:5334 ·
// 성공 1716:5393 · 직접입력 1991:7433) 구현. 하위 상태는 모두 State 로만 갈라진다 — 화면 push 없음.
@ViewAction(for: OnboardingJDLinkFeature.self)
public struct OnboardingJDLinkView: View {
    @Bindable public var store: StoreOf<OnboardingJDLinkFeature>

    public init(store: StoreOf<OnboardingJDLinkFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DashIndicator(count: store.totalSteps, current: store.step)
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    header
                    inputSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            if store.showsSkipTooltip {
                skipTooltip
            }
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .dismissesKeyboardOnTap()
        .hilitNavigationBar(
            background: .filled,
            onClose: { send(.userTappedClose) }
        )
        .onAppear { send(.onAppear) }
    }

    // MARK: - 공통 골격 (STEP 1 과 동일 — 프로그레스 바)

    // MARK: - 헤더

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 선택 스텝 뱃지 — STEP 1 «필수»(black/green)와 달리 회색 톤.
            Text("선택")
                .dsTypography(.body7)
                .foregroundStyle(Color.GrayScale.g800) // Figma 값 #31333B(grayscale/gray-800) — 토큰 충돌로 근사 (보고 참조)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.GrayScale.g50, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("채용공고 링크를\n업로드해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("채용 페이지에 직접 올라온 공고 링크를 넣어주세요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    // MARK: - 입력 영역 (탭 + 필드)

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            modeTabs
            switch store.mode {
            case .link:
                linkField
            case .directText:
                directTextField
            }
        }
    }

    private var modeTabs: some View {
        HStack(spacing: 0) {
            modeTab(.link, title: "JD 붙여넣기")
            modeTab(.directText, title: "직접 입력하기")
        }
    }

    private func modeTab(_ mode: OnboardingJDLinkFeature.InputMode, title: String) -> some View {
        let isSelected = store.mode == mode
        let isDisabled = mode == .directText && store.isDirectTextDisabled
        return Button {
            send(.userSelectedMode(mode))
        } label: {
            Text(title)
                .font(.ds(.body1))
                .foregroundStyle(isDisabled ? Color.GrayScale.g200 : Color.HilitBlack.b800)
                .frame(maxWidth: .infinity)
                .padding(10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle()
                    .fill(Color.HilitBlack.b800)
                    .frame(height: 1)
            }
        }
    }

    // MARK: - 링크 필드 (idle · loading · failure · success)

    private var linkField: some View {
        VStack(alignment: .leading, spacing: 8) {
            linkFieldBox
            linkHelperRow
        }
    }

    private var linkFieldBox: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                TextField(
                    "",
                    text: $store.linkText,
                    prompt: Text(Copy.fieldPlaceholder).foregroundStyle(Color.GrayScale.g600)
                )
                .font(.ds(.body3))
                .foregroundStyle(store.linkValidation == .loading ? Color.GrayScale.g600 : Color.HilitBlack.b800)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { send(.userSubmittedLink) }
                .disabled(store.isLinkFieldDisabled)

                switch store.linkValidation {
                case .loading:
                    Text("분석 중")
                        .dsTypography(.body8)
                        .foregroundStyle(Color.GrayScale.g900)
                case .idle, .failure, .success:
                    if !store.linkText.isEmpty {
                        clearButton(size: 16) { send(.userTappedClearLink) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(store.linkValidation == .loading ? Color.GrayScale.g50 : Color.BlackWhite.white)

            linkFieldBottomStrip
        }
        .overlay { linkFieldBorder }
    }

    /// 필드 하단 상태 스트립 — 로딩(진행 애니메이션)/에러(red)/성공(green). idle 은 없음.
    @ViewBuilder
    private var linkFieldBottomStrip: some View {
        switch store.linkValidation {
        case .idle:
            EmptyView()
        case .loading:
            AnalyzingProgressStrip()
        case .failure:
            Rectangle().fill(Color.Error.e500).frame(height: 4)
        case .success:
            Rectangle().fill(Color.HilitGreen.g500).frame(height: 4)
        }
    }

    /// idle 은 4변 보더, 스트립이 있는 상태는 상·좌·우 3변만 (하단은 스트립이 대신).
    @ViewBuilder
    private var linkFieldBorder: some View {
        if store.linkValidation == .idle {
            Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: 1.2)
        } else {
            OpenBottomBorder().stroke(Color.GrayScale.g100, lineWidth: 1.2)
        }
    }

    @ViewBuilder
    private var linkHelperRow: some View {
        switch store.linkValidation {
        case .idle:
            helperRow(icon: Image.Info.default, text: Copy.idleHelper, color: Color.GrayScale.g300)
        case .loading:
            EmptyView()
        case let .failure(message):
            helperRow(icon: Image.Issue.error16, text: message, color: Color.Error.e500)
        case .success:
            helperRow(icon: Image.Success.green16, text: Copy.successHelper, color: Color.HilitGreen.g800)
        }
    }

    private func helperRow(icon: Image, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(text)
                .dsTypography(.body5)
                .foregroundStyle(color)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 직접 입력 필드 (멀티라인)

    private var directTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            directTextEditorBox
            directTextFooter
        }
    }

    private var directTextEditorBox: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $store.directText)
                .font(.ds(.body3))
                .foregroundStyle(Color.HilitBlack.b800)
                .scrollContentBackground(.hidden)
                // TextEditor 고유 인셋(~5/8pt) 보정 — Figma px 16 / py 14 근사.
                .padding(.horizontal, 11)
                .padding(.vertical, 6)

            if store.directText.isEmpty {
                Text(Copy.fieldPlaceholder)
                    .font(.ds(.body3))
                    .foregroundStyle(Color.GrayScale.g600)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 158)
        .overlay(alignment: .topTrailing) {
            if !store.directText.isEmpty {
                clearButton(size: 24) { send(.userTappedClearDirectText) }
                    .padding(.top, 14)
                    .padding(.trailing, 16)
            }
        }
        .overlay {
            // 무효(짧음/초과) 입력이면 링크 에러와 같은 red 보더로 강조한다.
            Rectangle().strokeBorder(
                store.directTextValidationMessage == nil ? Color.GrayScale.g100 : Color.Error.e500,
                lineWidth: 1.2
            )
        }
    }

    /// 검증 안내(좌) + 글자수 카운터(우) — PRD S1 200~3,000자 게이팅.
    private var directTextFooter: some View {
        HStack(alignment: .top, spacing: 6) {
            if let message = store.directTextValidationMessage {
                Image.Issue.error16
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(message)
                    .dsTypography(.body5)
                    .foregroundStyle(Color.Error.e500)
            }
            Spacer(minLength: 0)
            Text(store.directTextCountLabel)
                .dsTypography(.body5)
                .foregroundStyle(store.isDirectTextOverLimit ? Color.Error.e500 : Color.GrayScale.g300)
        }
    }

    private func clearButton(size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            // 크기별 별도 에셋(optical sizing) — 20 미만이면 16px 판, 이상이면 24px 판.
            (size < 20 ? Image.CancelMini.gray16 : Image.CancelMini.gray24)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 스킵 안내 툴팁

    /// 입력이 빈 동안 CTA 위에 뜨는 안내 말풍선 (Figma 1935:3381) — 테일은 버블 우측단 기준 에셋.
    private var skipTooltip: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("링크 입력을 원하지 않으면 넘어가도 괜찮아요.")
                .dsTypography(.body4)
                .foregroundStyle(Color.BlackWhite.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color.HilitBlack.b800)
            Image.Img.tooltipTail
                .resizable()
                .scaledToFit()
                .frame(width: 97)
        }
        .padding(.bottom, 22)
    }

    // MARK: - 하단 CTA (이전으로 | 계속하기)

    /// 분할 CTA 바 — 뒤로가기가 네비바가 아니라 여기에 있다 (Figma 1609:9659).
    /// 한쪽만 비활성은 그 자식의 `.disabled` 로 표현한다 (DS 2버튼 규약).
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("이전으로") { send(.userTappedBack) }
        } trailing: {
            Button("계속하기") { send(.userTappedContinue) }
                .disabled(!store.isContinueEnabled)
        }
    }
}

// MARK: - 로딩 진행 스트립

/// 필드 하단의 불확정(indeterminate) 진행 표시 — 초록 조각이 좌→우로 흐른다 (Figma 1974:522 스냅숏 재현).
private struct AnalyzingProgressStrip: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            let chunkWidth = geometry.size.width * 0.26
            Color.GrayScale.g100
            Rectangle()
                .fill(Color.HilitGreen.g500)
                .frame(width: chunkWidth)
                .offset(x: isAnimating ? geometry.size.width : -chunkWidth)
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
        }
        .frame(height: 4)
        .clipped()
        .onAppear { isAnimating = true }
    }
}

// MARK: - 상·좌·우 3변 보더

/// 하단이 열린 보더 — 필드의 상태 스트립(로딩/에러/성공)이 하단 변을 대신할 때 쓴다.
private struct OpenBottomBorder: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

// MARK: - 카피

/// 화면 문구 — Figma 컴포넌트 기본 문구가 남아 있는 곳은 TODO 로 표시 (확정 카피 대기).
private enum Copy {
    /// Figma 리터럴 그대로 (text-field/Default 1974:468).
    static let fieldPlaceholder = "텍스트를 입력해주세요" // TODO: 확정 카피 반영
    /// Figma 는 필러 문구(«서브 텍스트를 입력해주세요») — 임시 초안.
    static let idleHelper = "채용 사이트의 공고 링크를 붙여넣으면 자동으로 분석해요." // TODO: 확정 카피 반영
    /// Figma 는 필러 문구 — 임시 초안.
    static let successHelper = "채용공고를 확인했어요." // TODO: 확정 카피 반영
}

// MARK: - Previews

#Preview("링크 입력 — 기본") {
    OnboardingJDLinkView(
        store: Store(initialState: OnboardingJDLinkFeature.State()) {
            OnboardingJDLinkFeature()
        }
    )
}

#Preview("링크 분석 중") {
    var state = OnboardingJDLinkFeature.State()
    state.linkText = "https://recruit.hilit.dev/jobs/123"
    state.linkValidation = .loading
    return OnboardingJDLinkView(
        store: Store(initialState: state) {
            OnboardingJDLinkFeature()
        }
    )
}

#Preview("링크 에러") {
    var state = OnboardingJDLinkFeature.State()
    state.linkText = "https://recruit.hilit.dev/jobs/123"
    state.linkValidation = .failure(message: "링크를 분석하지 못했어요. 링크를 확인해 주세요.")
    return OnboardingJDLinkView(
        store: Store(initialState: state) {
            OnboardingJDLinkFeature()
        }
    )
}

#Preview("링크 성공") {
    var state = OnboardingJDLinkFeature.State()
    state.linkText = "https://recruit.hilit.dev/jobs/123"
    state.linkValidation = .success
    return OnboardingJDLinkView(
        store: Store(initialState: state) {
            OnboardingJDLinkFeature()
        }
    )
}

#Preview("직접 입력 — 빈 값(스킵)") {
    var state = OnboardingJDLinkFeature.State()
    state.mode = .directText
    return OnboardingJDLinkView(
        store: Store(initialState: state) {
            OnboardingJDLinkFeature()
        }
    )
}

#Preview("직접 입력 — 200자 미만") {
    var state = OnboardingJDLinkFeature.State()
    state.mode = .directText
    state.directText = String(repeating: "가", count: 40)
    return OnboardingJDLinkView(
        store: Store(initialState: state) {
            OnboardingJDLinkFeature()
        }
    )
}
