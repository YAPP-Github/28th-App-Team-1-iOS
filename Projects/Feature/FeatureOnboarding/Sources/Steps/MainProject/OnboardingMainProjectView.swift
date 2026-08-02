//
//  OnboardingMainProjectView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «Onboarding_MainProject» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-9732
// 네비바는 닫기(X) + trailing «건너뛰기» — 뒤로가기는 하단 바의 «이전으로»가 담당한다 (이 스텝만의 이분할 CTA).
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 send(.userTappedContinue) 식으로만 방출.
@ViewAction(for: OnboardingMainProjectFeature.self)
public struct OnboardingMainProjectView: View {
    @Bindable public var store: StoreOf<OnboardingMainProjectFeature>

    public init(store: StoreOf<OnboardingMainProjectFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DashIndicator(count: store.totalSteps, current: store.step)
            ScrollView {
                VStack(alignment: .leading, spacing: .ds(.p24)) {
                    header
                    inputSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .ds(.p20))
            }
            if store.showsSkipTooltip {
                skipTooltip
                    .padding(.bottom, .ds(.p16))
            }
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .dismissesKeyboardOnTap()
        .hilitNavigationBar(
            trailing: .text("건너뛰기") { send(.userTappedSkip) },
            background: .filled,
            onClose: { send(.userTappedClose) }
        )
        .onAppear { send(.onAppear) }
    }

    /// «선택» 뱃지 + 2줄 마커 타이틀 + 서브 — Figma title-box 443:9746.
    /// 뱃지(I443:9746;2000:8288)는 회색 변형이라 `tagStyle: .grayGray` 를 넘긴다 (기본은 «필수» 검정 판).
    private var header: some View {
        TitleBox(
            [
                .init("집중적으로 보고싶은"),
                .init("프로젝트 내용을 알려주세요", highlight: "프로젝트 내용")
            ],
            tag: "선택",
            tagStyle: .grayGray,
            sub: "해당 프로젝트를 중점으로 면접이 진행돼요."
        )
        .padding(.top, .ds(.p20))
    }

    /// 라벨 + 여러 줄 입력 박스 — Figma 443:9747 / text-field 443:9749.
    /// 카운터(«n/300»)·300자 클램프·placeholder 는 전부 `HilitTextEditor` 가 소유한다 — 화면이 따로 그리지 않는다.
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: .ds(.p10)) {
            Text("프로젝트 내용 입력")
                .dsTypography(.body2)
                // @ds(color): #000000 → HilitBlack.b800 — 입력 라벨. 이 줄만 변수 미바인딩 raw 검정이고 팔레트에 순검정이 없다
                .foregroundStyle(Color.HilitBlack.b800)

            HilitTextEditor(
                Self.inputPlaceholder,
                text: $store.projectDescription,
                maxLength: OnboardingMainProjectFeature.State.maxTextLength
            )

            // 경고 상태는 지금 시안(443:9732)엔 없다 — 하한 미달(로컬 선검증)·연관성 실패(코디네이터 주입)로만
            // 켜지는 값이라 판 있는 DS 안내줄로 받는다. 문구가 길어 한 줄 말줄임인 `FieldSubText` 로는 안 들어간다.
            if let warning = store.inputWarning {
                InfoField(warning, style: .error)
            }
        }
        // @ds(spacing): 30 — 입력 섹션 상하 여백 (Figma 443:9747 py30, spacing 스케일에 30 이 없다)
        .padding(.vertical, Metric.inputSectionVerticalPadding)
    }

    /// «나중에 등록해도 괜찮아요!» 말풍선 — 선택 스텝 안내. 시안 주석이 «3초 후 사라짐»이고
    /// 그 타이머는 리듀서(`tooltipDuration`)가 갖는다. 꼬리는 «계속하기» 쪽(우하단)을 가리킨다.
    private var skipTooltip: some View {
        BubbleField("나중에 등록해도 괜찮아요!", .wide(tail: .bottom))
    }

    /// 하단 CTA — 이 스텝 고유의 이분할 바 («이전으로 | 계속하기»).
    /// 선택 스텝이라 계속하기는 항상 활성. 뒤로가기는 네비바가 아닌 여기서 처리한다.
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("이전으로") { send(.userTappedBack) }
        } trailing: {
            Button("계속하기") { send(.userTappedContinue) }
        }
    }

    /// 입력 박스 안내 문구 — Figma text-field 443:9749 placeholder 그대로.
    private static let inputPlaceholder =
        "프로젝트에서 담당하신 주요 내용을 담아 10글자 이상 작성해 주세요. AI가 프로젝트를 더 좋은 면접 질문을 만들 수 있어요."

    private enum Metric {
        /// 입력 섹션 상하 여백 — Figma 443:9747 py30.
        static let inputSectionVerticalPadding: CGFloat = 30
    }
}

// MARK: - Previews

// 네비바는 시스템 바라 `NavigationStack` 안에서만 그려진다 — 프리뷰도 스택으로 감싼다.
#Preview("대표 프로젝트 — 빈 입력") {
    NavigationStack {
        OnboardingMainProjectView(
            store: Store(initialState: OnboardingMainProjectFeature.State()) {
                OnboardingMainProjectFeature()
            }
        )
    }
}

#Preview("대표 프로젝트 — 입력 중") {
    NavigationStack {
        OnboardingMainProjectView(
            store: Store(
                initialState: OnboardingMainProjectFeature.State(
                    projectDescription: "결제 시스템 리팩토링, Redis 캐시 도입"
                )
            ) {
                OnboardingMainProjectFeature()
            }
        )
    }
}

#Preview("대표 프로젝트 — 300자 상한") {
    NavigationStack {
        OnboardingMainProjectView(
            store: Store(
                initialState: OnboardingMainProjectFeature.State(
                    projectDescription: String(repeating: "가", count: 300)
                )
            ) {
                OnboardingMainProjectFeature()
            }
        )
    }
}

#Preview("대표 프로젝트 — 하한 미달 경고") {
    NavigationStack {
        OnboardingMainProjectView(
            store: Store(
                initialState: OnboardingMainProjectFeature.State(
                    projectDescription: "짧은글",
                    inputWarning: OnboardingMainProjectFeature.lengthWarningMessage
                )
            ) {
                OnboardingMainProjectFeature()
            }
        )
    }
}
