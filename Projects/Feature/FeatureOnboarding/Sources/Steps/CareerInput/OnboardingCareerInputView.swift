//
//  OnboardingCareerInputView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «STEP 2_연차» (node 1609:8561) 구현.
// 구성: 내비바(X만) · 프로그레스(2/5) · 헤더(필수 뱃지+타이틀+설명) · 문장형 연차 휠 · 하단 «이전으로|계속하기» 바.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.userTappedBack) 로만 방출.
@ViewAction(for: OnboardingCareerInputFeature.self)
public struct OnboardingCareerInputView: View {
    @Bindable public var store: StoreOf<OnboardingCareerInputFeature>

    public init(store: StoreOf<OnboardingCareerInputFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DashIndicator(count: store.totalSteps, current: store.step)
            header
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            Spacer(minLength: 0)
            careerSentence
            Spacer(minLength: 0)
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(
            background: .filled,
            onClose: { send(.userTappedClose) }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("필수")
                .dsTypography(.body7)
                .foregroundStyle(Color.HilitGreen.g500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.HilitBlack.b800, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("연차를 입력해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("지금까지 근무한 모든 기간의 합\n(정규직·계약직·프리랜서 포함, 인턴)입니다.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    // MARK: - 문장형 연차 휠

    /// "내 경력은 [휠] 이다." — 앞뒤 텍스트가 휠의 선택 행(중앙)과 같은 줄에 놓인다.
    private var careerSentence: some View {
        HStack(spacing: 12) {
            Text("내 경력은")
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
            careerWheel
            Text("이다.")
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
        }
    }

    /// 연차 휠 — 세로 스크롤 + viewAligned 스냅으로 중앙 행이 선택값이 된다 (iOS 17 API).
    /// 상하 contentMargins 로 첫/마지막 항목도 중앙에 올 수 있고,
    /// 흰색 그라데이션 오버레이가 중앙 밖 행을 흐리게 가린다 (Figma «3안_mask» 재현).
    private var careerWheel: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(store.options, id: \.self) { option in
                    Text(option.label)
                        .dsTypography(.sub4)
                        .foregroundStyle(Color.HilitBlack.b800)
                        .frame(height: WheelMetric.rowHeight)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: wheelSelection, anchor: .center)
        .contentMargins(.vertical, WheelMetric.verticalMargin, for: .scrollContent)
        .scrollIndicators(.hidden)
        .frame(width: WheelMetric.width, height: WheelMetric.height)
        .overlay { wheelFade.allowsHitTesting(false) }
    }

    /// 휠 스크롤 위치 ↔ 상태 연결 — 스냅 결과만 view 액션으로 올리고, 상태가 바뀌면 휠도 따라 스크롤된다.
    private var wheelSelection: Binding<CareerOption?> {
        Binding(
            get: { store.selectedCareer },
            set: { option in
                guard let option, option != store.selectedCareer else { return }
                send(.userSelectedCareer(option))
            }
        )
    }

    /// 중앙 선택 행만 또렷하게 남기는 페이드 — Figma 그라데이션(비대칭 목업)의 대칭 정리판.
    private var wheelFade: some View {
        LinearGradient(
            stops: [
                .init(color: Color.BlackWhite.white, location: 0),
                .init(color: Color.BlackWhite.white.opacity(0.75), location: 0.22),
                .init(color: Color.BlackWhite.white.opacity(0), location: 0.38),
                .init(color: Color.BlackWhite.white.opacity(0), location: 0.62),
                .init(color: Color.BlackWhite.white.opacity(0.75), location: 0.78),
                .init(color: Color.BlackWhite.white, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 하단 바

    /// 하단 «이전으로 | 계속하기» 바 — 이 스텝은 STEP 1 의 단일 CTA 와 달리 2분할.
    /// 배경·구분선·등폭 배치·눌림은 `ButtonLarge(.bottom, tone: .dark)` 가 소유한다.
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("이전으로") { send(.userTappedBack) }
        } trailing: {
            Button("계속하기") { send(.userTappedContinue) }
        }
    }
}

// MARK: - WheelMetric

/// Figma «3안_mask» 치수 — 휠 마스크 146×206, 행 높이 44.
private enum WheelMetric {
    static let rowHeight: CGFloat = 44
    static let width: CGFloat = 146
    static let height: CGFloat = 206
    /// 첫/마지막 항목도 중앙 정렬이 가능하도록 하는 스크롤 상하 여백.
    static let verticalMargin: CGFloat = (height - rowHeight) / 2
}

// MARK: - Previews

#Preview("연차 입력 — 기본(신입)") {
    OnboardingCareerInputView(
        store: Store(initialState: OnboardingCareerInputFeature.State()) {
            OnboardingCareerInputFeature()
        }
    )
}

/// 휠 중앙에 «3년차».
#Preview("연차 입력 — 3년차 선택") {
    OnboardingCareerInputView(
        store: Store(
            initialState: OnboardingCareerInputFeature.State(selectedCareer: CareerOption(years: 3))
        ) {
            OnboardingCareerInputFeature()
        }
    )
}
