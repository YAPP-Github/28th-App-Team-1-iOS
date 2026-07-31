//
//  HomeDefaultView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home / Home_Default» https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-16965

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 홈 기본 상태 — 커튼 그린 배경 위 인사말 + 스크롤 유도 문구, 하단은 «면접 리포트» 시트(빈 상태).
///
/// 시트는 아직 **정적 판**이다. 시안 문구가 말하는 «밑으로 스크롤»(시트를 끌어올려 면접 시작으로 넘어가는
/// 전환)은 phase 를 바꾸는 제스처라 리듀서 액션이 생긴 뒤 배선한다 — 그래버도 지금은 표시용이다.
///
/// dev 임시 버튼 2개는 위젯①(면접 시작)·마이페이지 로그아웃이 정식 배선되면 제거한다.
@ViewAction(for: HomeFeature.self)
struct HomeDefaultView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ZStack {
            curtainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                greenHeader
                reportSheet
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // 인사말의 colorBurn 이 «배경 커튼까지만» 섞이도록 합성 경계를 여기서 닫는다.
        .compositingGroup()
        .hilitLogoNavigationBar(background: .filled, onProfile: {
            // TODO: 마이페이지 진입 — 리듀서에 userTappedProfile 이 생기면 send 로 교체.
        })
    }

    // MARK: - 그린 영역 (내비바 ~ 시트 위)

    /// 인사말 + 스크롤 안내. 높이는 내용이 정하고(시안 244), 남은 높이는 시트가 먹는다 —
    /// 시안에서 안내 문구 프레임의 아래변이 시트 상단과 정확히 맞물린다.
    private var greenHeader: some View {
        VStack(spacing: 0) {
            greeting
                // @ds(spacing): 54 — 내비바 아래 ~ 인사말 (spacing 토큰은 4~24)
                .padding(.top, 54)
            scrollHint
                // @ds(spacing): 60 — 인사말 ~ 스크롤 안내 (spacing 토큰은 4~24)
                .padding(.top, 60)
        }
        .frame(maxWidth: .infinity)
    }

    private var greeting: some View {
        // TODO: 이름은 서버 프로필(nickname) — State 에 값이 생기면 교체 (필요한 State: userName).
        Text("오랜만이에요\n재원님!")
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(component): mix-blend-mode color-burn — 인사말이 배경 커튼과 타서 초록으로 보이는 효과. DS 에 블렌드 규칙 없음
            .blendMode(.colorBurn)
    }

    private var scrollHint: some View {
        // @ds(typography): Pretendard Medium 16 / 행간 140% / 자간 -2% → body3 — 스크롤 유도 문구 (토큰 행간은 130%)
        Text("밑으로 스크롤해서 면접을 시작해 보세요!")
            .dsTypography(.body3)
            .foregroundStyle(Color.HilitGreen.g800)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .ds(.p10))
            .padding(.vertical, .ds(.p16))
            .padding(.horizontal, .ds(.p20))
    }

    // MARK: - 리포트 시트

    /// 하단 흰 판 — 그래버 + 개수 헤더 + 빈 상태. 빈 상태는 헤더와 무관하게 **판 중앙**에 놓인다(시안 기준).
    private var reportSheet: some View {
        ZStack {
            VStack(spacing: 0) {
                sheetGrabber
                sheetHeader
                devEntries
                Spacer(minLength: 0)
            }
            emptyReportState
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 판 색만 홈 인디케이터 영역까지 내리고, 내용은 safe area 안에 둔다 — 시안의 중앙 정렬이 그 기준이다.
        .background(Color.BlackWhite.white.ignoresSafeArea(edges: .bottom))
    }

    // @ds(component): 60×5 바 (모서리 없음) — 시트 그래버. DS 에 시트 컴포넌트 없음(`.hilitBottomSheet` 는 모달 딤 전용)
    private var sheetGrabber: some View {
        Rectangle()
            .fill(Color.GrayScale.g400)
            .frame(width: 60, height: 5)
            .frame(height: 20)
    }

    private var sheetHeader: some View {
        // TODO: 개수는 홈 진입 로드의 리포트 목록 — State 에 값이 생기면 교체 (필요한 State: reportCount).
        (
            Text("면접 리포트 ").foregroundStyle(Color.HilitBlack.b800)
                + Text("0개").foregroundStyle(Color.GrayScale.g500)
        )
        .dsTypography(.sub7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p10))
    }

    private var emptyReportState: some View {
        VStack(spacing: .ds(.p12)) {
            // 100pt 그대로 — 크기별 별도 에셋 규칙상 리사이즈하지 않는다.
            Image.Img.reportEmpty
            Text("면접을 보고\n레포트를 받아보세요")
                .dsTypography(.body2)
                .foregroundStyle(Color.GrayScale.g400)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - dev 임시 진입

    /// 시안에 없는 dev 전용 버튼 — 배포 계에선 플래그가 꺼져 숨겨진다.
    @ViewBuilder
    private var devEntries: some View {
        if store.showsOnboardingEntry || store.showsDebugLogout {
            HStack(spacing: .ds(.p8)) {
                // dev 전용 임시 진입 — 온보딩 본체 통합 전까지 실서버 API 확인용.
                if store.showsOnboardingEntry {
                    Button("온보딩 시작 (dev)") {
                        send(.userTappedOnboarding)
                    }
                    .buttonStyle(.borderedProminent)
                }

                // dev 디버그 — 서버 로그아웃 + 토큰·온보딩 draft 전체 삭제 후 첫 로그인 화면으로.
                if store.showsDebugLogout {
                    Button("로그아웃 (dev)", role: .destructive) {
                        send(.userTappedLogout)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, .ds(.p20))
            .padding(.top, .ds(.p8))
        }
    }

    // MARK: - 배경 커튼

    /// 그린 판 위에 세로 밴드 8개(흰 그라데이션)를 겹친 장식 배경 — 위·아래는 흰색으로 덮이고
    /// 가운데 띠만 그린이 비쳐 커튼 주름처럼 보인다. 상단이 흰색이라 내비바(흰 판)와 이음새가 없다.
    // @ds(component): 세로 밴드 8개 × 흰 그라데이션 정지점 — 홈 전용 장식 배경, DS 에 없음
    private var curtainBackground: some View {
        HStack(spacing: 0) {
            ForEach(Self.curtainBands.indices, id: \.self) { index in
                LinearGradient(
                    stops: Self.curtainBands[index].map {
                        Gradient.Stop(color: Color.BlackWhite.white.opacity($0.opacity), location: $0.location)
                    },
                    startPoint: .top,
                    endPoint: .bottom
                )
                // @ds(spacing): 0.2 — 밴드 경계선 두께 (DSOutline 최소가 1)
                .border(Color.BlackWhite.white, width: 0.2)
            }
        }
        .background(Color.HilitGreen.g500)
    }

    /// 밴드별 흰색 정지점 — `location` 은 화면 전체 높이 비율(시안 812pt 기준의 % 를 그대로 옮긴 값)이라
    /// 기기 높이가 달라도 같은 비율로 늘어난다. 밴드마다 정지점이 달라 주름이 불규칙해 보인다.
    private static let curtainBands: [[(opacity: Double, location: CGFloat)]] = [
        [(1, 0.136), (0.4, 0.325), (1, 1)],
        [(1, 0.115), (0.4, 0.257), (0.3, 0.475), (0.4, 0.589), (1, 1)],
        [(1, 0.118), (0.4, 0.231), (0.2, 0.394), (0.1, 0.504), (0.4, 0.684), (1, 1)],
        [(1, 0.117), (0.3, 0.234), (0.1, 0.317), (0.1, 0.397), (0.3, 0.688), (1, 1)],
        [(1, 0.133), (0.3, 0.244), (0.1, 0.393), (0.1, 0.508), (0.3, 0.626), (1, 1)],
        [(1, 0.122), (0.4, 0.274), (0.2, 0.375), (0.1, 0.512), (0.4, 0.690), (1, 1)],
        [(1, 0.142), (0.4, 0.328), (0.3, 0.429), (0.4, 0.590), (1, 1)],
        [(1, 0.140), (0.4, 0.513), (1, 1)]
    ]
}

#Preview("HomeDefault — 시안") {
    HomeDefaultView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}

#Preview("HomeDefault — dev 버튼") {
    HomeDefaultView(
        store: Store(initialState: HomeFeature.State(showsOnboardingEntry: true, showsDebugLogout: true)) {
            HomeFeature()
        }
    )
}
