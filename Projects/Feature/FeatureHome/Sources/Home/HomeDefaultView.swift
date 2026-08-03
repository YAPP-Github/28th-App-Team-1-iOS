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
/// 시안 문구가 말하는 «밑으로 스크롤»(면접 시작으로 넘어가는 전환)은 시트 하향 드래그와
/// 안내 문구 탭 두 경로로 배선했다 — 자리·임계값은 `HomeSheetDrag` 참조(모션 시안 없음).
/// 리포트 자리와 달리 **확장 자리는 없다** — 펼칠 목록이 없어서다.
///
/// 그린 배경·면접 시작 레이어·내비바·시트 높이는 전부 `HomeView` 가 소유한다.
///
/// dev 데이터 초기화 버튼은 시안에 없는 개발용이다 — 배포 계에선 플래그가 꺼져 숨겨진다.
@ViewAction(for: HomeFeature.self)
struct HomeDefaultView: View {
    @Bindable var store: StoreOf<HomeFeature>
    /// 시트 판 높이 — 이 phase 엔 확장 자리가 없어 기본 자리 높이로 고정이다.
    /// 내려갈 땐 높이가 아니라 `sheetOffset` 이 움직인다 — 내용 좌표계가 판과 1:1 로 붙어 있다.
    let sheetHeight: CGFloat
    /// 판을 통째로 밀어 내린 거리(아래가 +) — 바텀시트가 미끄러져 사라지는 모양(`HomeSheetDrag.dismissOffset`).
    let sheetOffset: CGFloat
    /// 면접 시작이 드러난 정도(0…1) — 그린 영역은 그만큼 사라진다.
    let startProgress: Double
    let dragHandle: HomeSheetDragHandle

    /// 그린 영역은 **겹**으로 깔고 시트가 그 위를 덮는다 — 세로로 나눠 담으면(VStack) 시트가 높이를
    /// 먼저 먹어 그린 영역이 눌리고 인사말이 잘린다. 시트가 남길 자리는 `HomeSheetDrag` 가 보장한다.
    var body: some View {
        ZStack(alignment: .bottom) {
            greenHeader
                .opacity(1 - startProgress)
            reportSheet
                .frame(height: sheetHeight)
                .offset(y: sheetOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 그린 영역 (내비바 ~ 시트 위)

    /// 인사말 + 스크롤 안내. 내용은 위에 붙고(시안 244 안), 아래 남은 자리를 시트가 덮는다 —
    /// 시안에서 안내 문구 프레임의 아래변이 시트 상단과 정확히 맞물린다.
    private var greenHeader: some View {
        VStack(spacing: 0) {
            greeting
                // @ds(spacing): 54 — 내비바 아래 ~ 인사말 (spacing 토큰은 4~24)
                .padding(.top, 54)
            scrollHint
                // @ds(spacing): 60 — 인사말 ~ 스크롤 안내 (spacing 토큰은 4~24)
                .padding(.top, 60)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    private var greeting: some View {
        // 이름은 프로필 로드 결과라 응답 전엔 비어 있다 — 그때는 «님!» 만 남지 않게 이름 줄을 뺀다.
        Text(store.userName.isEmpty ? "오랜만이에요!" : "오랜만이에요\n\(store.userName)님!")
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(component): mix-blend-mode color-burn — 인사말이 배경 커튼과 타서 초록으로 보이는 효과. DS 에 블렌드 규칙 없음
            .blendMode(.colorBurn)
    }

    /// 스크롤 안내 — 문구가 약속한 «면접 시작» 을 이 영역 탭으로도 연다.
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
            .contentShape(Rectangle())
            .onTapGesture { send(.userTappedStartInterview, animation: HomeSheetDrag.settleAnimation) }
    }

    // MARK: - 리포트 시트

    /// 하단 흰 판 — 그래버 + 개수 헤더 + 빈 상태. 빈 상태는 헤더와 무관하게 **판 중앙**에 놓인다(시안 기준).
    /// 판은 줄지 않는다 — 내려갈 땐 부모가 `sheetOffset` 으로 통째로 밀어 내려 내용이 판과 같이 움직인다.
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // 판 색만 홈 인디케이터 영역까지 내리고, 내용은 safe area 안에 둔다 — 시안의 중앙 정렬이 그 기준이다.
        // 다 내려가면 판이 통째로 화면 밖이라(offset) 띠를 따로 지울 필요가 없다.
        .background {
            Color.BlackWhite.white
                .ignoresSafeArea(edges: .bottom)
        }
        // 이 phase 의 시트엔 스크롤이 없어 판 전체를 손잡이로 쓸 수 있다.
        .contentShape(Rectangle())
        .gesture(dragHandle.gesture)
    }

    // @ds(component): 60×5 바 (모서리 없음) — 시트 그래버. DS 에 시트 컴포넌트 없음(`.hilitBottomSheet` 는 모달 딤 전용)
    private var sheetGrabber: some View {
        Rectangle()
            .fill(Color.GrayScale.g400)
            .frame(width: 60, height: 5)
            .frame(height: 20)
    }

    private var sheetHeader: some View {
        (
            Text("면접 리포트 ").foregroundStyle(Color.HilitBlack.b800)
                + Text("\(store.reports.count)개").foregroundStyle(Color.GrayScale.g500)
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
    /// 서버 로그아웃 + 토큰·UserDefaults 전체 삭제 후 Splash 부터 다시 태운다(재설치와 같은 자리).
    @ViewBuilder
    private var devEntries: some View {
        if store.showsDevReset {
            Button("데이터 전부 삭제 후 재시작 (dev)", role: .destructive) {
                send(.userTappedResetAppData)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, .ds(.p20))
            .padding(.top, .ds(.p8))
        }
    }
}

// 배경·면접 시작 레이어·내비바는 `HomeView` 소유라 프리뷰도 거기서 띄운다.
#Preview("HomeDefault — 시안") {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State()) {
                HomeFeature()
            }
        )
    }
}

#Preview("HomeDefault — dev 버튼") {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State(showsDevReset: true)) {
                HomeFeature()
            }
        )
    }
}
