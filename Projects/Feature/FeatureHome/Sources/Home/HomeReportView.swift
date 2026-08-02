//
//  HomeReportView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_Report» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-17266

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// Figma «Home_Report»(3368:17266) — 면접 기록(레포트) 표시 상태.
///
/// 상단은 그린 판(스트라이프 배경 + 인사 문구 + 스크롤 안내), 하단은 리포트 목록 바텀시트다.
/// 리포트 행은 foldable — 펼친 행 1개(다크 카드 + 제목 + 보기 버튼)와 접힌 행 N개(날짜만)로 그린다.
/// 펼침 상태·목록·이름은 모두 `HomeFeature.State` 소유다.
///
/// 인사 문구는 조건부 표시다 — `phase` 가 `.report(.recent)` 면 블록 자체가 레이아웃에서 빠지고
/// 스크롤 안내만 남는다(시안에 hidden 변형이 없어 안내 문구 위치는 바텀시트 기준으로 유지).
///
/// 그린 배경·면접 시작 레이어·내비바·시트 높이는 전부 `HomeView` 가 소유한다 — 여기는 받은 높이에
/// 맞춰 그리고, 손잡이를 어디에 둘지만 정한다.
@ViewAction(for: HomeFeature.self)
struct HomeReportView: View {
    @Bindable var store: StoreOf<HomeFeature>
    /// 지금 시트가 차지할 높이 — 확정된 자리 + 진행 중인 드래그.
    let sheetHeight: CGFloat
    /// 면접 시작이 드러난 정도(0…1) — 그린 판은 그만큼 사라진다.
    let startProgress: Double
    let dragHandle: HomeSheetDragHandle

    /// 인사 문구 표시 여부 — report 변형이 결정한다(`returning` 만 띄운다).
    private var isGreetingVisible: Bool {
        store.phase == .report(.returning)
    }

    var body: some View {
        VStack(spacing: 0) {
            greenPanel
                .opacity(1 - startProgress)
            reportSheet
                .frame(height: sheetHeight)
        }
    }

    // MARK: - 상단 그린 판

    /// 시트가 먹고 남은 높이를 그대로 쓴다 — 확장 자리에선 0 까지 줄어 잘려 나간다.
    /// 위쪽에 붙여 두면 올라오는 시트가 안내 문구부터 차례로 덮는다(가운데 정렬이면 내용이 떠다닌다).
    private var greenPanel: some View {
        VStack(spacing: 0) {
            if isGreetingVisible {
                greeting
            }
            Spacer(minLength: .ds(.p20))
            scrollHint
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    /// 인사 문구 — 시안은 내비바 아래 54 지점에서 시작한다.
    private var greeting: some View {
        // @ds(color): mix-blend-color-burn — 인사 문구 블렌드 (DS 에 블렌드 규칙 없음, 그린 판 위에서만 성립)
        // 이름은 프로필 로드 결과라 응답 전엔 비어 있다 — 그때는 «님!» 만 남지 않게 이름 줄을 뺀다.
        Text(store.userName.isEmpty ? "오랜만이에요!" : "오랜만이에요\n\(store.userName)님!")
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .blendMode(.colorBurn)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(spacing): 54 — 내비바 하단 ~ 인사 문구 (spacing 토큰은 4~24 뿐)
            .padding(.top, 54)
    }

    /// 스크롤 안내 — 바텀시트 바로 위. 시안 프레임은 x20·w335 안에 px10·py16.
    /// 문구가 말하는 «면접 시작» 경로를 이 영역 탭으로도 연다(끌지 않는 지름길 — `HomeSheetDrag`).
    private var scrollHint: some View {
        // @ds(typography): Pretendard m16 / lh 1.4 / tracking -2% → body3 — 안내 문구 (토큰은 lh 1.3 · tracking -2.5%)
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

    // MARK: - 바텀시트

    /// 높이는 부모가 준다 — 내려가면 면접 시작이 드러나고, 올라가면 목록만 남는다.
    private var reportSheet: some View {
        VStack(spacing: 0) {
            grabber
            sheetHeader
            reportList
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background { sheetBackground }
        .clipped()
        .overlay(alignment: .bottom) { bottomFade }
    }

    /// 판 색만 홈 인디케이터 영역까지 내린다 — 시트가 완전히 내려가면 그 띠도 같이 사라져야
    /// 아래 겹(면접 시작 CTA)이 안 가려진다.
    private var sheetBackground: some View {
        Color.BlackWhite.white
            .opacity(sheetHeight > 0 ? 1 : 0)
            .ignoresSafeArea(edges: .bottom)
    }

    /// 손잡이 — 시안은 라운드 없는 막대다. 위아래로 끌어 시트 자리를 바꾼다.
    /// 제스처를 손잡이·헤더에만 두는 이유: 목록은 `ScrollView` 라 같은 축의 드래그가 겹친다.
    // @ds(component): 그래버 60×5 (컨테이너 h20) — 바텀시트 손잡이, 공용 컴포넌트 없음
    private var grabber: some View {
        Color.GrayScale.g400
            .frame(width: 60, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(dragHandle.gesture)
    }

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            (
                Text("면접 리포트 ").foregroundStyle(Color.HilitBlack.b800)
                    + Text("\(store.reports.count)개").foregroundStyle(Color.GrayScale.g500)
            )
            .dsTypography(.sub7)
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.top, .ds(.p10))
        .padding(.bottom, .ds(.p20))
        .contentShape(Rectangle())
        .gesture(dragHandle.gesture)
    }

    /// 목록 — 행 사이 1pt 흰 틈이 그대로 구분선이 된다(시안 gap 1).
    private var reportList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(store.reports) { report in
                    if report.id == store.expandedReportID {
                        expandedRow(report)
                    } else {
                        collapsedRow(report)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 펼친 행 — 다크 카드에 날짜·제목·[레포트 보기] 버튼.
    private func expandedRow(_ report: HomeFeature.Report) -> some View {
        VStack(alignment: .trailing, spacing: .ds(.p16)) {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                Text(report.dateText)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.HilitGreen.g500)
                Text(report.title)
                    .dsTypography(.sub4)
                    .foregroundStyle(Color.BlackWhite.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                send(.userTappedReport(id: report.id))
            } label: {
                Image.Right.default24
                    .padding(.ds(.p10))
                    .background(Color.HilitGreen.g500)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p24))
        .frame(maxWidth: .infinity)
        .background(Color.HilitBlack.b800)
    }

    /// 접힌 행 — 날짜만. 탭하면 펼친다(리듀서가 토글).
    private func collapsedRow(_ report: HomeFeature.Report) -> some View {
        Button {
            send(.userTappedReportRow(id: report.id))
        } label: {
            Text(report.dateText)
                .dsTypography(.body3)
                // @ds(color): #0A1C1F → HilitBlack.b900 — 접힌 행 날짜. 시안값은 변수 미바인딩 raw 라
                //   팔레트 최근접(#121316, Δ≈9)으로 통일했다 (사용자 결정 2026-07-31)
                .foregroundStyle(Color.HilitBlack.b900)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.ds(.p20))
                .background(Self.collapsedRowBackground)
        }
        .buttonStyle(.plain)
    }

    /// 하단 페이드 — 목록이 시트 밑으로 이어진다는 신호(시안 «video overlay» 76pt).
    private var bottomFade: some View {
        // @ds(color): white 0 → 0.4(50%) → 1(109.21%) — 목록 하단 페이드. 109.21% 는 1.0 으로 clamp
        LinearGradient(
            stops: [
                .init(color: Color.BlackWhite.white.opacity(0), location: 0),
                .init(color: Color.BlackWhite.white.opacity(0.4), location: 0.4995),
                .init(color: Color.BlackWhite.white, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        // @ds(layout): 76 — 하단 페이드 높이
        .frame(height: 76)
        .allowsHitTesting(false)
    }

    // MARK: - 시안 raw 값

    // @ds(color): #D2EFCC (Figma «hilit green/200») — 접힌 리포트 행 배경. 팔레트에 그린 200 단계가 없다
    private static let collapsedRowBackground = Color(red: 210 / 255, green: 239 / 255, blue: 204 / 255)
}

// MARK: - Previews

// 배경·면접 시작 레이어·내비바는 `HomeView` 소유라 프리뷰도 거기서 띄운다 — 자리별 모습은
// `sheetDetent` 를 바꿔 본다(`onAppear` 가 기본 자리로 되돌리므로 확장 자리는 손으로 끌어 확인).
#Preview("HomeReport — 인사 문구 표시") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.returning),
                    reports: HomeFeature.Report.placeholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}

#Preview("HomeReport — 인사 문구 숨김") {
    NavigationStack {
        HomeView(
            store: Store(
                initialState: HomeFeature.State(
                    phase: .report(.recent),
                    reports: HomeFeature.Report.placeholders
                )
            ) {
                HomeFeature()
            }
        )
    }
}
