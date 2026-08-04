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
        .overlay(alignment: .bottom) { if !isEmpty { bottomFade } }
    }

    /// 판 색만 홈 인디케이터 영역까지 내린다 — 다 내려가면 판이 통째로 화면 밖이라(offset)
    /// 띠를 따로 지울 필요가 없다.
    private var sheetBackground: some View {
        Color.BlackWhite.white
            .ignoresSafeArea(edges: .bottom)
    }

    /// 손잡이 — 시안은 라운드 없는 막대다. 위아래로 끌어 시트 자리를 바꾼다.
    /// 판 안에서 손잡이가 되는 자리는 그래버·헤더 + (스크롤이 없는) 빈 상태 판·기본 자리 목록이다.
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
            VStack(spacing: 0) {
                devEntries
                Spacer(minLength: 0)
            }
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
    /// **기본 자리에선 목록 위 스와이프가 «시트 올리기» 다** — 시안(649:6625)이 약속하는 «위로 스크롤하면
    /// 목록만 남는다» 를 그 제스처로 잇는다. 스크롤과 시트 드래그는 **같은 축**이라 동시에 걸면 서로
    /// 먹으므로, 자리에 따라 한쪽만 산다: 기본 자리 = 시트 드래그(스크롤 끔) / 확장 자리 = 목록 스크롤.
    /// 확장 자리에서 다시 내려오는 길은 헤더 드래그다.
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
        .scrollDisabled(!isExpanded)
        // 확장 자리에선 목록이 스크롤을 가져가므로 시트 드래그를 뺀다(`.subviews` = 부모 제스처 비활성).
        .gesture(dragHandle.gesture, including: isExpanded ? .subviews : .all)
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
            // 생성 중·분석 부족·실패 세션은 열 상세가 없어 버튼을 아예 뺀다 — 제목 자리가 상태 안내다.
            if report.canOpenReport {
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

    // MARK: - 시안 raw 값

    // @ds(color): #D2EFCC (Figma «hilit green/200») — 접힌 리포트 행 배경. 팔레트에 그린 200 단계가 없다
    private static let collapsedRowBackground = Color(red: 210 / 255, green: 239 / 255, blue: 204 / 255)
}

// MARK: - Previews

// 판만 떼어 행 레이아웃을 본다 — 배경·인사말·자리 전환이 있는 모습은 `HomeView` 프리뷰가 담당한다.
#Preview("리포트 시트 — 목록") {
    HomeReportSheet(
        store: Store(
            initialState: HomeFeature.State(
                phase: .report(.returning),
                reports: HomeFeature.Report.statusPlaceholders
            )
        ) {
            HomeFeature()
        },
        dragHandle: HomeSheetDragHandle(onChanged: { _ in }, onEnded: { _ in })
    )
    .frame(height: 481)
}

#Preview("리포트 시트 — 빈 상태") {
    HomeReportSheet(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        },
        dragHandle: HomeSheetDragHandle(onChanged: { _ in }, onEnded: { _ in })
    )
    .frame(height: 481)
}
