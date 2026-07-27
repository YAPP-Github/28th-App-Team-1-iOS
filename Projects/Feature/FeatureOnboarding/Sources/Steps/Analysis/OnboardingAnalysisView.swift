//
//  OnboardingAnalysisView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «6. 분석 중»(node 1609:9019) · «6.1 분석 완료»(node 1609:9075) 구현.
// 풀스크린 다크(HilitBlack.b800) 화면 — 프로그레스 바·STEP 라벨·뒤로가기 없음, 좌상단 닫기(X)만 있다.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.onAppear) 로만 방출.
@ViewAction(for: OnboardingAnalysisFeature.self)
public struct OnboardingAnalysisView: View {
    @Bindable public var store: StoreOf<OnboardingAnalysisFeature>

    public init(store: StoreOf<OnboardingAnalysisFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(Color.HilitBlack.b800.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .onAppear { send(.onAppear) }
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.dark24
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

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch store.phase {
            case .analyzing:
                analyzingContent
            case .completed:
                completedContent
            case let .failed(message):
                failedContent(message: message)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 분석 중 (1609:9019)

    private var analyzingContent: some View {
        VStack(spacing: 45) {
            header(
                title: "최적의 면접 환경을\n준비하고 있어요",
                subtitle: "잠시만 기다려주세요",
                subtitleColor: Color.GrayScale.g100
            )
            .background { gradientBand }
            checklist
        }
        // Figma: 콘텐츠 블록이 화면 세로 중앙보다 위(타이틀 top 269/812) — 중앙 정렬에 위쪽 보정.
        .padding(.bottom, 96)
    }

    /// Figma 1991:10274 — 타이틀 뒤 대각선 그라데이션 밴드. 화면 폭(375)을 넘어 좌우로 흘러나간다.
    private var gradientBand: some View {
        LinearGradient(
            colors: [Color.HilitGreen.g500, Color.analysisBandTail],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 677, height: 156)
        .rotationEffect(.degrees(7))
    }

    /// 순차 진행 체크리스트 — completedStages 앞은 체크, 그 자리는 스피너, 뒤는 대기 링.
    private var checklist: some View {
        VStack(alignment: .leading, spacing: 10) {
            analysisRow("기본정보 분석 중", index: 0)
            analysisRow("채용 정보 분석 중", index: 1)
            analysisRow("나의 포폴 분석 중", index: 2)
        }
        .animation(.easeInOut(duration: 0.25), value: store.completedStages)
    }

    private func analysisRow(_ title: String, index: Int) -> some View {
        HStack(spacing: 6) {
            stageIndicator(index: index)
            Text(title)
                .dsTypography(.body2)
                .foregroundStyle(Color.BlackWhite.white)
        }
    }

    @ViewBuilder
    private func stageIndicator(index: Int) -> some View {
        if index < store.completedStages {
            Image.Success.green16
                .resizable()
                .scaledToFit()
                .frame(width: SpinnerMetrics.box, height: SpinnerMetrics.box)
                .transition(.scale.combined(with: .opacity))
        } else if index == store.completedStages {
            AnalysisSpinner()
        } else {
            AnalysisTrackRing()
        }
    }

    // MARK: - 분석 완료 (1609:9075)

    private var completedContent: some View {
        header(
            title: "면접 환경을\n준비했어요",
            subtitle: "이제부터 시작해볼까요?",
            subtitleColor: Color.GrayScale.g200
        )
        // Figma: 완료 블록 중심 y ≈ 369.5/812 — 중앙 정렬에 위쪽 보정.
        .padding(.bottom, 136)
    }

    // MARK: - 분석 실패 (세션 생성·폴링 실패 — 디자인 미정, 근사)

    /// 재시도 없음(PRD §3.1) — 좌상단 X 로 이탈해 처음부터 다시 시도한다.
    private func failedContent(message: String) -> some View {
        header(
            title: "면접 준비에 실패했어요",
            subtitle: message,
            subtitleColor: Color.GrayScale.g100
        )
        .padding(.bottom, 96)
    }

    // MARK: - 공통

    private func header(title: String, subtitle: String, subtitleColor: Color) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .dsTypography(.head3)
                .foregroundStyle(Color.BlackWhite.white)
            Text(subtitle)
                .dsTypography(.sub8)
                .foregroundStyle(subtitleColor)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AnalysisSpinner

/// Figma «Component 5/24px» 공통 치수 — 24px 박스 안 링 지름 17.35 · 선굵기 2.37 근사.
private enum SpinnerMetrics {
    static let box: CGFloat = 24
    static let ring: CGFloat = 17.4
    static let line: CGFloat = 2.4
}

/// Figma «Component 5/24px/dark default» 근사 — gray-700 트랙 링 위를 도는 그린 아크.
/// 원본 에셋(scratchpad step6-assets/IcAnalysisSpinner*.svg): 아크 약 108°.
/// Lottie 등 외부 라이브러리 없이 회전 애니메이션으로 재현한다.
private struct AnalysisSpinner: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.GrayScale.g700, lineWidth: SpinnerMetrics.line)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.HilitGreen.g500, lineWidth: SpinnerMetrics.line)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
        }
        .frame(width: SpinnerMetrics.ring, height: SpinnerMetrics.ring)
        .frame(width: SpinnerMetrics.box, height: SpinnerMetrics.box)
        .onAppear { isSpinning = true }
    }
}

/// 아직 차례가 오지 않은 행의 대기 인디케이터 — 스피너와 같은 치수의 트랙 링만.
private struct AnalysisTrackRing: View {
    var body: some View {
        Circle()
            .stroke(Color.GrayScale.g700, lineWidth: SpinnerMetrics.line)
            .frame(width: SpinnerMetrics.ring, height: SpinnerMetrics.ring)
            .frame(width: SpinnerMetrics.box, height: SpinnerMetrics.box)
    }
}

private extension Color {
    /// 그라데이션 밴드 종점 · #1A3C14 — Figma 변수 미바인딩 raw 값이라 DS 토큰화 보류 (colors.md 규칙).
    static let analysisBandTail = Color(red: 26 / 255, green: 60 / 255, blue: 20 / 255)
}

// MARK: - Previews

private let previewData = OnboardingData(
    userName: "재원",
    jobRole: "BACKEND",
    careerYears: 1,
    portfolioId: UUID(uuidString: "00000000-0000-0000-0000-0000000000f1")!
)

#Preview("분석 중") {
    var state = OnboardingAnalysisFeature.State(data: previewData)
    state.hasStartedAnalysis = true   // onAppear 의 실제 세션 호출을 막고 분석 화면만 본다.
    return OnboardingAnalysisView(
        store: Store(initialState: state) {
            OnboardingAnalysisFeature()
        }
    )
}

#Preview("분석 중 — 2행 진행") {
    var state = OnboardingAnalysisFeature.State(data: previewData)
    state.hasStartedAnalysis = true
    state.completedStages = 1   // 1행 체크 · 2행 스피너 · 3행 대기 링
    return OnboardingAnalysisView(
        store: Store(initialState: state) {
            OnboardingAnalysisFeature()
        }
    )
}

#Preview("분석 완료") {
    var state = OnboardingAnalysisFeature.State(data: previewData)
    state.phase = .completed
    state.hasStartedAnalysis = true
    return OnboardingAnalysisView(
        store: Store(initialState: state) {
            OnboardingAnalysisFeature()
        }
    )
}

#Preview("분석 실패") {
    var state = OnboardingAnalysisFeature.State(data: previewData)
    state.phase = .failed(message: OnboardingAnalysisFeature.failureMessage)
    state.hasStartedAnalysis = true
    return OnboardingAnalysisView(
        store: Store(initialState: state) {
            OnboardingAnalysisFeature()
        }
    )
}
