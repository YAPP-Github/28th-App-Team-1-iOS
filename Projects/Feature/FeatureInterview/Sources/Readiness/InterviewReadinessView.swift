//
//  InterviewReadinessView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «[2] Interview_Readiness»(2479:7569) · «…_Done»(2514:12754) · «…_Guide1»(2514:12799)
// · «…_Guide2»(2529:458) 구현. 전면 카메라 배경 위 오버레이만 phase 로 갈아끼운다.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.onAppear) 로만 방출.
@ViewAction(for: InterviewReadinessFeature.self)
public struct InterviewReadinessView: View {
    @Bindable public var store: StoreOf<InterviewReadinessFeature>

    public init(store: StoreOf<InterviewReadinessFeature>) {
        self.store = store
    }

    private var isGuidePhase: Bool {
        store.phase == .guide1 || store.phase == .guide2
    }

    public var body: some View {
        ZStack {
            InterviewCameraBackdrop()

            CameraGuideFrame(showsCenterText: !isGuidePhase)

            VStack(spacing: 0) {
                titleBox
                Spacer(minLength: 0)
                bottomArea
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .onAppear { send(.onAppear) }
    }

    // MARK: - 타이틀 (component/title-box — 상단 고정 밴드)

    /// Figma title-box: 상태바 아래 51pt 지점부터. 2줄(68pt) 밴드를 고정해 1줄 타이틀(guide2)도
    /// 같은 시각 중심(y≈128)에 온다 (Figma top 94 vs 110 보정).
    private var titleBox: some View {
        VStack(spacing: 0) {
            switch store.phase {
            case .aligning, .ready:
                titleLine {
                    titleText("면접을 준비하고 있어요")
                }
                titleLine {
                    titleText("화면 속")
                    titleHighlight("내 모습")
                    titleText("을 확인해주세요")
                }
            case .guide1:
                titleLine {
                    titleText("질문은")
                    titleHighlight("소리")
                    titleText("로만 나와요")
                }
                titleLine {
                    titleText("실제 면접처럼 잘 듣고 대답하면 돼요")
                }
            case .guide2:
                titleLine {
                    titleText("면접은 총")
                    titleHighlight("10분")
                    titleText("으로 진행돼요")
                }
            }
        }
        .frame(minHeight: 68)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .ds(.p20))
        .padding(.top, 51)
    }

    private func titleLine(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 0) { content() }
    }

    private func titleText(_ text: String) -> some View {
        Text(text)
            .dsTypography(.head3)
            .foregroundStyle(Color.BlackWhite.white)
    }

    /// 한 낱말만 마커 처리 — 문장 조립은 호출부(`titleLine`)가 하므로 낱말 전체가 강조 구간이다.
    private func titleHighlight(_ text: String) -> some View {
        HighlightedText(text, typography: .head3)
            .hilightColor(.green)
    }

    // MARK: - 하단 (티커 ↔ 시작 버튼)

    @ViewBuilder
    private var bottomArea: some View {
        switch store.phase {
        case .aligning, .ready:
            InterviewTicker(
                text: "곧 면접이 시작됩니다",
                isEmphasized: store.phase == .ready
            )
            .padding(.bottom, 94)
        case .guide1, .guide2:
            ButtonLarge("면접 시작하기", .bottom) {
                send(.userTappedStart)
            }
            .disabled(store.phase == .guide1)
        }
    }
}

// MARK: - InterviewTicker

/// Figma «loading/text»(2479:7556) — gray-800 풀폭 스트립에 같은 문구 3연속(간격 6).
/// 중앙만 상태에 따라 밝아진다: 대기 gray-600 → 준비 완료 gray-50. 양옆은 gray-700 고정.
private struct InterviewTicker: View {
    var text: String
    var isEmphasized: Bool

    var body: some View {
        HStack(spacing: 6) {
            sideText
            Text(text)
                .dsTypography(.sub7)
                .foregroundStyle(isEmphasized ? Color.GrayScale.g50 : Color.GrayScale.g600)
            sideText
        }
        .lineLimit(1)
        .fixedSize()
        .frame(maxWidth: .infinity)
        .background(Color.GrayScale.g800)
        .clipped()
    }

    private var sideText: some View {
        Text(text)
            .dsTypography(.sub7)
            .foregroundStyle(Color.GrayScale.g700)
    }
}

// MARK: - Previews

#Preview("얼굴 맞춤 (aligning)") {
    var state = InterviewReadinessFeature.State()
    state.hasStarted = true   // onAppear 의 phase 타이머를 막고 이 상태만 본다.
    return InterviewReadinessView(
        store: Store(initialState: state) {
            InterviewReadinessFeature()
        }
    )
}

#Preview("준비 완료 (ready)") {
    var state = InterviewReadinessFeature.State()
    state.phase = .ready
    state.hasStarted = true
    return InterviewReadinessView(
        store: Store(initialState: state) {
            InterviewReadinessFeature()
        }
    )
}

#Preview("가이드 1 — 버튼 비활성") {
    var state = InterviewReadinessFeature.State()
    state.phase = .guide1
    state.hasStarted = true
    return InterviewReadinessView(
        store: Store(initialState: state) {
            InterviewReadinessFeature()
        }
    )
}

#Preview("가이드 2 — 버튼 활성") {
    var state = InterviewReadinessFeature.State()
    state.phase = .guide2
    state.hasStarted = true
    return InterviewReadinessView(
        store: Store(initialState: state) {
            InterviewReadinessFeature()
        }
    )
}
