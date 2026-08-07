//
//  HomeReportSheet.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_Default» 빈 상태 https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-16965
// Figma: «Home_Report» 목록     https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-17266
// Figma: «Home_Report — 확장 자리(목록만)» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=649-6625

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 홈 하단 흰 판 — 그래버 + «면접 리포트 N개» 헤더 + 내용. **판은 하나고 내용만 갈린다**:
/// 기록이 없으면 빈 상태 일러스트, 있으면 foldable 목록(펼친 행 1 + 접힌 행 N).
///
/// 높이·자리·오프셋은 전부 `HomeView` 소유다 — 여기는 받은 프레임 안을 그리고 «어디를 잡을 수 있는지»만 정한다.
/// 확장 자리(시안 649:6625)엔 그래버가 없고 헤더가 내비바 바로 밑에 붙는다.
@ViewAction(for: HomeFeature.self)
struct HomeReportSheet: View {
    @Bindable var store: StoreOf<HomeFeature>
    let dragHandle: HomeSheetDragHandle

    /// 확장 자리 — 시트가 내비바 밑까지 올라와 목록만 남은 상태.
    private var isExpanded: Bool {
        store.sheetDetent == .expanded
    }

    /// 기록이 없는 상태 — 목록 대신 빈 상태를 그리고 확장 자리도 성립하지 않는다.
    private var isEmpty: Bool {
        store.phase == .default
    }

    var body: some View {
        VStack(spacing: 0) {
            // 확장 자리 시안엔 그래버가 없다 — 헤더가 손잡이를 이어받으므로 내려올 길은 남는다.
            if !isExpanded {
                grabber
            }
            sheetHeader
            content
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background { sheetBackground }
        // 빈 상태는 헤더와 무관하게 **판 중앙**이다(시안) — 그래서 스택 안이 아니라 판 전체 overlay 다.
        .overlay { if isEmpty { emptyState } }
        .clipped()
        .overlay(alignment: .top) { topBarShadow }
        .overlay(alignment: .bottom) { if !isEmpty { bottomFade } }
    }

    /// 확장 자리에서 내비바가 판 위로 드리우는 그림자 — 시안 649:6652 top-bar
    /// `drop-shadow(0 8 6, #DDDFE5 60%)`. 판이 내비바에 붙는 자리에서만 보인다.
    ///
    /// 시스템 툴바에는 그림자를 붙일 수 없어(`toolbarBackground` 는 색만 받는다) **판 쪽에서**
    /// 같은 그림을 그린다 — 그림자는 어차피 아래 판 위에 떨어지는 것이라 결과가 같다.
    /// 자리 확정(`sheetDetent`) 뒤에 켜지므로 끌고 있는 동안은 안 보인다 — 붙고 나서 생기는 게 맞다.
    private var topBarShadow: some View {
        LinearGradient(
            colors: [Self.topBarShadowColor, Self.topBarShadowColor.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        // @ds(layout): 14 = 그림자 y8 + blur 6 — 번지는 거리
        .frame(height: 14)
        .opacity(isExpanded ? 1 : 0)
        .animation(HomeSheetDrag.settleAnimation, value: isExpanded)
        .allowsHitTesting(false)
    }

    /// 판 색만 홈 인디케이터 영역까지 내린다 — 다 내려가면 판이 통째로 화면 밖이라(offset)
    /// 띠를 따로 지울 필요가 없다.
    private var sheetBackground: some View {
        Color.BlackWhite.white
            .ignoresSafeArea(edges: .bottom)
    }

    /// 손잡이 — DS `SheetGrabber`(라운드 없는 막대). 위아래로 끌어 시트 자리를 바꾼다.
    /// 오버레이 시트라 드래그가 OS 몫이 아니어서 제스처를 직접 붙인다.
    /// 판 안에서 `DragGesture` 를 받는 자리는 그래버·헤더 + (스크롤이 없는) 빈 상태 판이다.
    /// 목록 판은 제스처 대신 `HomeSheetScrollView` 브리지가 이동량을 나눠 받는다.
    private var grabber: some View {
        SheetGrabber()
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
        // 확장 자리는 그래버가 빠진 만큼 위를 20 으로 벌린다 — 시안 헤더 프레임 63 = 20 + 23 + 20.
        .padding(.top, isExpanded ? .ds(.p20) : .ds(.p10))
        .padding(.bottom, .ds(.p20))
        .contentShape(Rectangle())
        .gesture(dragHandle.gesture)
    }

    // MARK: - 내용

    @ViewBuilder
    private var content: some View {
        if isEmpty {
            // 빈 상태 판엔 스크롤이 없어 남은 자리 전체가 손잡이다(일러스트는 판 전체 overlay).
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(dragHandle.gesture)
        } else {
            reportList
        }
    }

    private var emptyState: some View {
        VStack(spacing: .ds(.p12)) {
            // 100pt 그대로 — 크기별 별도 에셋 규칙상 리사이즈하지 않는다.
            Image.Img.reportEmpty
            Text("면접을 보고\n레포트를 받아보세요")
                .dsTypography(.body2)
                .foregroundStyle(Color.GrayScale.g400)
                .multilineTextAlignment(.center)
        }
        .allowsHitTesting(false)
    }

    /// 목록 — 행 사이 1pt 흰 틈이 그대로 구분선이 된다(시안 gap 1).
    ///
    /// 스크롤과 시트 드래그는 **같은 축**이라 자리별로 한쪽만 살리면 손짓이 두 번 필요해진다
    /// (올리고 → 놓고 → 다시 스크롤). 그래서 통을 `HomeSheetScrollView` 브리지로 바꿔 **한 손짓**으로
    /// 잇는다: 기본 자리에선 이동량이 시트로 흘러 판이 올라오고, 확장 높이에 닿으면 그대로 목록
    /// 스크롤이 된다(시안 649:6625 의 «위로 스크롤하면 목록만 남는다»). 확장 자리에서 목록 맨 위를
    /// 아래로 당기면 반대로 시트가 내려온다 — 헤더 드래그 말고도 내려올 길이 생긴다.
    ///
    /// 브리지 안에선 lazy 가 얹힐 스크롤 지오메트리가 없어(행이 전부 즉시 생성된다) `VStack` 을 쓴다 —
    /// 행이 4개 안팎이라 잃는 게 없고, 고유 높이가 그대로 잡혀 contentSize 계산이 단순해진다.
    private var reportList: some View {
        HomeSheetScrollView(dragHandle: dragHandle, isExpanded: isExpanded) {
            VStack(spacing: 1) {
                ForEach(store.reports) { report in
                    if store.expandedReportIDs.contains(report.id) {
                        expandedRow(report)
                    } else {
                        collapsedRow(report)
                    }
                }
            }
        }
        // 헤더 아래 남은 자리를 통이 다 먹는다 — 예전 `ScrollView` 와 같은 자리를 명시로 못 박는다.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 펼친 행 — 다크 카드에 날짜·제목·[레포트 보기] 버튼. 카드 본문을 탭하면 도로 접힌다
    /// ([>] 버튼은 자기 탭을 먹으므로 접힘과 겹치지 않는다).
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
                // 생성 실패 행만 붙는 보조 문구 — «횟수는 안 깎였다» (시안 2026-08-05).
                if let subtitle = report.subtitle {
                    Text(subtitle)
                        .dsTypography(.body6)
                        .foregroundStyle(Color.GrayScale.g400)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // 생성 실패 세션은 열 상세가 없어 버튼을 아예 뺀다 — 카드에 상태 문구만 남는다.
            if report.canOpenReport {
                // TODO: Part 3 리포트 상세 진입 — delegate 는 이미 나간다(`reportDetailRequested(id:)`,
                //       인자 = 세션 id). 남은 건 AppFeature 에서 `InterviewReportFeature` 를 제시하는 것뿐이다.
                Button {
                    send(.userTappedReport(id: report.id))
                } label: {
                    Image.Right.default24
                        .padding(.ds(.p10))
                        .background(Color.HilitGreen.g500)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p24))
        .frame(maxWidth: .infinity)
        .background(Color.HilitBlack.b800)
        // 카드 전체가 접기 영역 — 빈 자리(텍스트 사이·여백)도 먹게 모양을 채운다.
        .contentShape(Rectangle())
        .onTapGesture { send(.userTappedReportRow(id: report.id)) }
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

    // @ds(color): #DDDFE5 60% — 내비바 드롭섀도 색. 팔레트에 이 단계가 없다(g100 #EBECF1 ~ g200 #BCBEC6 사이)
    private static let topBarShadowColor = Color(red: 221 / 255, green: 223 / 255, blue: 229 / 255)
        .opacity(0.6)
}

// MARK: - Previews

// 판만 떼어 행 레이아웃을 본다 — 배경·인사말·자리 전환이 있는 모습은 `HomeView` 프리뷰가 담당한다.
#Preview("리포트 시트 — 목록") {
    HomeReportSheet(
        store: Store(
            initialState: HomeFeature.State(
                phase: .report(.returning),
                reports: HomeFeature.Report.snapshotPlaceholders
            )
        ) {
            HomeFeature()
        },
        dragHandle: HomeSheetDragHandle(onChanged: { _ in }, onEnded: { _ in .report })
    )
    .frame(height: 481)
}

// 확장 자리(649:6625) — 그래버 없이 헤더부터 시작하고, 판 위쪽에 내비바 그림자가 깔린다.
#Preview("리포트 시트 — 확장 자리(내비바 그림자)") {
    var state = HomeFeature.State(
        phase: .report(.returning),
        reports: HomeFeature.Report.snapshotPlaceholders
    )
    state.sheetDetent = .expanded
    return HomeReportSheet(
        store: Store(initialState: state) { HomeFeature() },
        dragHandle: HomeSheetDragHandle(onChanged: { _ in }, onEnded: { _ in .report })
    )
}

#Preview("리포트 시트 — 빈 상태") {
    HomeReportSheet(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        },
        dragHandle: HomeSheetDragHandle(onChanged: { _ in }, onEnded: { _ in .report })
    )
    .frame(height: 481)
}
