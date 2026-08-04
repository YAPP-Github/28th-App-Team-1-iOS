//
//  OnboardingPreloadView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «Onboarding_preload» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-9768
// 풀스크린 다크(HilitBlack.b800) 프리로드 화면 — 프로그레스 대시·뒤로가기 없음, 좌상단 닫기(X)만 있다.
// 화면 아래쪽은 오른쪽으로 기운 그린 사면이 덮고, 그 위 가운데에 타이틀·서브·분석 체크리스트가 얹힌다.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.onAppear) 로만 방출.
@ViewAction(for: OnboardingPreloadFeature.self)
public struct OnboardingPreloadView: View {
    @Bindable public var store: StoreOf<OnboardingPreloadFeature>

    public init(store: StoreOf<OnboardingPreloadFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.HilitBlack.b800
            greenSlope
            content
        }
        // 시안 좌표가 상태바·홈 인디케이터를 포함한 375×812 프레임 기준이라 풀블리드로 놓고 잰다 —
        // 그린 사면이 화면 바닥까지 닿아야 하고, 콘텐츠 중앙도 «프레임 중앙» 기준이다.
        .ignoresSafeArea()
        .hilitNavigationBar(
            surface: .dark,
            background: .filled,
            allowsSwipeBack: false,   // 제출 중 이탈 = 세션 생성 버림
            onClose: { send(.userTappedClose) }
        )
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .onAppear { send(.onAppear) }
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
        .padding(.horizontal, .ds(.p20))
        // @ds(layout): top calc(50% - 29.5) — 콘텐츠 블록이 화면 세로 중앙보다 위 (443:9773)
        .offset(y: -29.5)
    }

    // MARK: - 분석 중 (443:9773)

    private var analyzingContent: some View {
        // @ds(spacing): 32 — 헤더 ↔ 체크리스트 (DSSpacing 에 32 없음)
        VStack(spacing: 32) {
            header(
                title: "최적의 면접 환경을\n준비하고 있어요",
                subtitle: "잠시만 기다려주세요"
            )
            checklist
        }
    }

    /// 순차 진행 체크리스트 — completedStages 앞은 체크, 그 자리는 스피너, 뒤는 대기 링.
    /// 블록 자체는 가운데 정렬이고 행 안만 왼쪽 정렬이다 (Figma 443:9778 — 335 폭에서 좌우 여백이 같다).
    private var checklist: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            analysisRow("기본정보 분석 중", index: 0)
            analysisRow("채용 정보 분석 중", index: 1)
            analysisRow("나의 포폴 분석 중", index: 2)
        }
        .animation(.easeInOut(duration: 0.25), value: store.completedStages)
    }

    private func analysisRow(_ title: String, index: Int) -> some View {
        HStack(spacing: .ds(.p10)) {
            stageIndicator(index: index)
            // @ds(typography): m16 · 행간 140% · 자간 -2% → body3(130% · -2.5%) — 체크리스트 행 라벨.
            // 시안이 텍스트 스타일 변수를 안 물린 raw 값이라 현행 토큰으로 흡수한다 (사고 사례 18번).
            Text(title)
                .dsTypography(.body3)
                .foregroundStyle(Color.BlackWhite.white)
        }
    }

    /// 행 앞 인디케이터 — 완료는 그린 체크, 진행 중은 스피너, 대기는 트랙 링. 전부 색이 구워진 DS 에셋이다.
    /// 슬롯을 16 으로 고정하되 `resizable` 은 걸지 않는다 — `loading/*/16px` 에셋의 캔버스가 17 이라
    /// 리사이즈하면 획이 얇아진다(사고 사례 2번). 프레임은 자리만 잡고 글리프는 원래 크기로 그린다.
    private func stageIndicator(index: Int) -> some View {
        Group {
            if index < store.completedStages {
                Image.Success.green16
                    .transition(.scale.combined(with: .opacity))
            } else if index == store.completedStages {
                PreloadSpinner()
            } else {
                Image.Loading.waitBlack16
            }
        }
        .frame(width: 16, height: 16)
    }

    // MARK: - 그린 사면 (443:9769)

    /// 화면 아래를 덮는 그린 사면 — 시안은 6.31° 기운 980×318 사각형이지만, 375 폭에서 보이는 것은
    /// «왼쪽 변이 바닥에서 284.5pt 인 빗변 아래 전부» 다. 회전 사각형을 그대로 옮기지 않고 폭에 맞춰
    /// 다시 그리는 Shape 로 두어 기기 폭이 달라져도 기울기·바닥 여백이 유지된다.
    private var greenSlope: some View {
        PreloadSlope()
            .fill(Self.slopeGradient)
            // @ds(layout): 284.5 — 왼쪽 변 기준 사면 높이 (375×812 시안, 화면 바닥 기준)
            .frame(height: 284.5)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }

    /// 시안의 189.47° 그라데이션에 사각형 회전 6.31° 를 더해 화면 좌표로 되돌린 것.
    /// 정지점(23.2% · 70.4%)이 실제로 놓이는 지점을 시안 좌표에서 계산해 UnitPoint 로 옮겼다 —
    /// 그래서 색 배열은 정지점 없이 두 색만 둔다.
    private static let slopeGradient = LinearGradient(
        colors: [.preloadSlopeHead, .preloadSlopeTail],
        startPoint: UnitPoint(x: 0.728, y: 0.224),
        endPoint: UnitPoint(x: 0.566, y: 0.981)
    )

    // MARK: - 분석 완료 (새 시안에 대응 노드 없음 — 분석 중 판의 헤더 규격을 따른다)

    private var completedContent: some View {
        header(
            title: "면접 환경을\n준비했어요",
            subtitle: "이제부터 시작해볼까요?"
        )
    }

    // MARK: - 분석 실패 (세션 생성·폴링 실패 — 디자인 미정, 근사)

    /// 재시도 없음(PRD §3.1) — 좌상단 X 로 이탈해 처음부터 다시 시도한다.
    private func failedContent(message: String) -> some View {
        header(
            title: "면접 준비에 실패했어요",
            subtitle: message
        )
    }

    // MARK: - 공통

    private func header(title: String, subtitle: String) -> some View {
        VStack(spacing: .ds(.p8)) {
            Text(title)
                .dsTypography(.head3)
                .foregroundStyle(Color.BlackWhite.white)
            Text(subtitle)
                .dsTypography(.sub8)
                .foregroundStyle(Color.GrayScale.g300)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 사면 Shape

// @ds(component): 화면 바닥을 덮는 사선 판 — 공용 컴포넌트 없음. `Parallelogram` 은 텍스트 마커용이라
// 기울기가 «높이와 무관한 고정 오프셋 4pt» 로 고정이고, 여기 필요한 «각도 고정» 빗변과 성질이 다르다.
/// 그린 사면 — 왼쪽 위 꼭짓점에서 오른쪽으로 `angle` 만큼 내려가는 빗변 아래를 채운다.
private struct PreloadSlope: Shape {
    /// Figma 443:9769 사각형의 회전각. 375 폭에서 좌우 변 높이차 41.5pt.
    static let angle = Angle.degrees(6.31)

    func path(in rect: CGRect) -> Path {
        let drop = rect.width * CGFloat(tan(Self.angle.radians))
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + drop))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - PreloadSpinner

/// 진행 중 행의 스피너 — DS 에셋 `loading/ing/16px/black`(`Image.Loading.ingBlack16`)을 무한 회전시킨다.
/// 트랙(gray-700)·아크(green-500) 색이 에셋에 구워져 있어 틴트는 통하지 않는다 (사고 사례 1번).
/// `SaveIndicator.Spinner` 와 같은 패턴 — `@State` 를 별도 뷰에 묶어 두면 행이 체크로 바뀌며 사라졌다가
/// 되돌아와도 `onAppear` 가 애니메이션을 되살린다.
private struct PreloadSpinner: View {
    @State private var isSpinning = false

    var body: some View {
        Image.Loading.ingBlack16
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
    }
}

private extension Color {
    // @ds(color): #89E377 — 그린 사면 시작색. Figma 변수 미바인딩 raw 값이라 토큰화 보류 (color.md 규칙).
    static let preloadSlopeHead = Color(red: 137 / 255, green: 227 / 255, blue: 119 / 255)
    // @ds(color): #60D549 — 그린 사면 끝색. 같은 이유로 보류.
    static let preloadSlopeTail = Color(red: 96 / 255, green: 213 / 255, blue: 73 / 255)
}

// MARK: - Previews

private let previewData = OnboardingData(
    userName: "재원",
    portfolioId: UUID(uuidString: "00000000-0000-0000-0000-0000000000f1")!
)

#Preview("분석 중") {
    var state = OnboardingPreloadFeature.State(data: previewData)
    state.hasStartedAnalysis = true   // onAppear 의 실제 세션 호출을 막고 분석 화면만 본다.
    return OnboardingPreloadView(
        store: Store(initialState: state) {
            OnboardingPreloadFeature()
        }
    )
}

#Preview("분석 중 — 2행 진행") {
    var state = OnboardingPreloadFeature.State(data: previewData)
    state.hasStartedAnalysis = true
    state.completedStages = 1   // 1행 체크 · 2행 스피너 · 3행 대기 링
    return OnboardingPreloadView(
        store: Store(initialState: state) {
            OnboardingPreloadFeature()
        }
    )
}

#Preview("분석 완료") {
    var state = OnboardingPreloadFeature.State(data: previewData)
    state.phase = .completed
    state.hasStartedAnalysis = true
    return OnboardingPreloadView(
        store: Store(initialState: state) {
            OnboardingPreloadFeature()
        }
    )
}

#Preview("분석 실패") {
    var state = OnboardingPreloadFeature.State(data: previewData)
    state.phase = .failed(message: OnboardingPreloadFeature.failureMessage)
    state.hasStartedAnalysis = true
    return OnboardingPreloadView(
        store: Store(initialState: state) {
            OnboardingPreloadFeature()
        }
    )
}
