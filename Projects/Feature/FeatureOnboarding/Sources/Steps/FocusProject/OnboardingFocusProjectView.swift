//
//  OnboardingFocusProjectView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «STEP 5_집중 프로젝트» (node 1609:10016) 구현.
// 내비바는 닫기(X)만 — 뒤로가기는 하단 바의 «이전으로»가 담당한다 (이 스텝만의 이분할 CTA).
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 send(.userTappedContinue) 식으로만 방출.
@ViewAction(for: OnboardingFocusProjectFeature.self)
public struct OnboardingFocusProjectView: View {
    @Bindable public var store: StoreOf<OnboardingFocusProjectFeature>

    public init(store: StoreOf<OnboardingFocusProjectFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            progressBar
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
                    .padding(.bottom, 20)
            }
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .dismissesKeyboardOnTap()
        .navigationBarBackButtonHidden(true)
        .onAppear { send(.onAppear) }
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.default24
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }

    private var progressBar: some View {
        HStack(spacing: 2) {
            ForEach(1...store.totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= store.step ? Color.HilitBlack.b800 : Color.GrayScale.g50)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("선택")
                .dsTypography(.body7)
                .foregroundStyle(Color.GrayScale.g800)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.GrayScale.g50, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("집중적으로 보고싶은\n프로젝트 내용을 알려주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                // PRD S3 확정 문구 — 입력/건너뛰기 결과를 함께 안내(기존 스킵과 모순되던 카피 폐기).
                Text("입력하면 그 부분을 집중 검증해요.\n건너뛰면 포트폴리오 전체에서 질문해요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("프로젝트 내용 입력")
                .dsTypography(.body1)
                .foregroundStyle(Color.HilitBlack.b800)

            HStack(spacing: 4) {
                projectTextField
                if store.isClearButtonVisible {
                    clearButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .overlay {
                Rectangle()
                    .strokeBorder(Color.GrayScale.g100, lineWidth: 1.5)
            }

            Text(store.characterCountLabel)
                .dsTypography(.body6)
                .foregroundStyle(Color.GrayScale.g700)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let warning = store.inputWarning {
                HStack(spacing: 6) {
                    Image.Issue.error16
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(warning)
                        .dsTypography(.body5)
                        .foregroundStyle(Color.Error.e500)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var projectTextField: some View {
        TextField(
            "",
            text: $store.projectDescription,
            prompt: Text("결제 시스템 리팩토링, Redis 캐시 도입")
                .font(.ds(.body2))
                .foregroundStyle(Color.GrayScale.g100)
        )
        // TODO: 입력(filled) 상태 텍스트 색 Figma 미확인 — placeholder 상태만 제공돼 우선 gray800.
        .font(.ds(.body2))
        .foregroundStyle(Color.GrayScale.g800)
        .tint(Color.HilitBlack.b800)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 24) // 클리어 버튼(24pt) 유무와 무관하게 입력창 높이 고정.
    }

    private var clearButton: some View {
        Button {
            send(.userTappedClearText)
        } label: {
            // 원본 컬러 에셋(회색 원 + 블랙 X) — 틴트 없이 그대로 렌더.
            Image.CancelMini.grey24
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }

    /// «나중에 등록해도 괜찮아요!» 말풍선 — 선택 스텝 안내. 꼬리는 «계속하기» 쪽(우측)을 가리킨다.
    private var skipTooltip: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("나중에 등록해도 괜찮아요!")
                .dsTypography(.body4)
                .foregroundStyle(Color.BlackWhite.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(Color.HilitBlack.b800)
            Image.Img.tooltipTail
                .resizable()
                .scaledToFit()
                .frame(width: 97, height: 11)
        }
        .frame(width: 274)
    }

    /// 하단 CTA — 이 스텝 고유의 이분할 바 («이전으로 | 계속하기»).
    /// 선택 스텝이라 계속하기는 항상 활성. 뒤로가기는 내비바가 아닌 여기서 처리한다.
    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedBack)
            } label: {
                Text("이전으로")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.GrayScale.g700)
                .frame(width: 1, height: 25)

            Button {
                send(.userTappedContinue)
            } label: {
                Text("계속하기")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color.HilitBlack.b800.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Previews

#Preview("집중 프로젝트 — 빈 입력") {
    OnboardingFocusProjectView(
        store: Store(initialState: OnboardingFocusProjectFeature.State()) {
            OnboardingFocusProjectFeature()
        }
    )
}

#Preview("집중 프로젝트 — 입력 중") {
    OnboardingFocusProjectView(
        store: Store(
            initialState: OnboardingFocusProjectFeature.State(
                projectDescription: "결제 시스템 리팩토링, Redis 캐시 도입"
            )
        ) {
            OnboardingFocusProjectFeature()
        }
    )
}

#Preview("집중 프로젝트 — 300자 상한") {
    OnboardingFocusProjectView(
        store: Store(
            initialState: OnboardingFocusProjectFeature.State(
                projectDescription: String(repeating: "가", count: 300)
            )
        ) {
            OnboardingFocusProjectFeature()
        }
    )
}
