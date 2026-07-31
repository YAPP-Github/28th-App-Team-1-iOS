//
//  HomeReportView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_Report» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3368-17266

import SharedDesignSystemInterface
import SwiftUI

/// Figma «Home_Report»(3368:17266) — 면접 기록(레포트) 표시 상태.
///
/// 상단은 그린 판(스트라이프 배경 + 인사 문구 + 스크롤 안내), 하단은 리포트 목록 바텀시트다.
/// 리포트 행은 foldable — 펼친 행 1개(다크 카드 + 제목 + 보기 버튼)와 접힌 행 N개(날짜만)로 그린다.
///
/// 인사 문구는 조건부 표시다 — `isGreetingVisible` 이 false 면 블록 자체가 레이아웃에서 빠지고
/// 스크롤 안내만 남는다(시안에 hidden 변형이 없어 안내 문구 위치는 바텀시트 기준으로 유지).
///
/// 리듀서에 리포트 목록·펼침 상태가 아직 없어 표시 모델·펼침은 뷰가 들고 있다 — 배선 시
/// `HomeFeature.State` 로 올린다(필요한 Action 은 작업 보고 참조).
struct HomeReportView: View {

    /// 리포트 행 표시 모델 — 도메인 타입이 붙기 전까지의 뷰 전용 표현.
    /// `dateText` 는 이미 포맷된 문자열이다(«7월 11일 월» 포맷은 도메인·리듀서 몫).
    struct Report: Identifiable, Equatable {
        let id: UUID
        let dateText: String
        let title: String

        init(id: UUID = UUID(), dateText: String, title: String) {
            self.id = id
            self.dateText = dateText
            self.title = title
        }
    }

    /// 인사 문구 표시 여부 — 첫 진입·재방문 판정에 따라 켜고 끈다.
    var isGreetingVisible: Bool = true
    /// 인사 문구에 넣는 사용자 이름.
    var userName: String = "재원"
    /// 리포트 목록 — 리듀서가 목록을 들기 전까지 시안 값이 기본값이다.
    var reports: [Report] = Report.placeholders
    /// 프로필 탭 — 배선 전까지 nil(내비바가 빈 슬롯을 유지한다).
    var onProfileTapped: (() -> Void)?
    /// 펼친 행의 [레포트 보기] 탭.
    var onReportTapped: ((Report.ID) -> Void)?

    /// 펼친 행 — 시안은 최신 1개가 펼쳐진 상태다.
    @State private var expandedReportID: Report.ID?

    var body: some View {
        VStack(spacing: 0) {
            greenPanel
            reportSheet
        }
        .background { HomeGreenBackdrop() }
        .ignoresSafeArea(edges: .bottom)
        .hilitLogoNavigationBar(background: .filled, onProfile: onProfileTapped)
        .onAppear { expandedReportID = expandedReportID ?? reports.first?.id }
    }

    // MARK: - 상단 그린 판

    private var greenPanel: some View {
        VStack(spacing: 0) {
            if isGreetingVisible {
                greeting
            }
            Spacer(minLength: .ds(.p20))
            scrollHint
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 인사 문구 — 시안은 내비바 아래 54 지점에서 시작한다.
    private var greeting: some View {
        // @ds(color): mix-blend-color-burn — 인사 문구 블렌드 (DS 에 블렌드 규칙 없음, 그린 판 위에서만 성립)
        Text("오랜만이에요\n\(userName)님!")
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .blendMode(.colorBurn)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(spacing): 54 — 내비바 하단 ~ 인사 문구 (spacing 토큰은 4~24 뿐)
            .padding(.top, 54)
    }

    /// 스크롤 안내 — 바텀시트 바로 위. 시안 프레임은 x20·w335 안에 px10·py16.
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
    }

    // MARK: - 바텀시트

    private var reportSheet: some View {
        VStack(spacing: 0) {
            grabber
            sheetHeader
            reportList
        }
        .frame(maxWidth: .infinity, alignment: .top)
        // @ds(layout): 481 — 바텀시트 판 높이 (시안 812 중 하단 481, 드래그 확장 시안 없음)
        .frame(height: 481)
        .background(Color.BlackWhite.white)
        .clipped()
        .overlay(alignment: .bottom) { bottomFade }
    }

    /// 손잡이 — 시안은 라운드 없는 막대다.
    // @ds(component): 그래버 60×5 (컨테이너 h20) — 바텀시트 손잡이, 공용 컴포넌트 없음
    private var grabber: some View {
        Color.GrayScale.g400
            .frame(width: 60, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: 20)
    }

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            (
                Text("면접 리포트 ").foregroundStyle(Color.HilitBlack.b800)
                    + Text("\(reports.count)개").foregroundStyle(Color.GrayScale.g500)
            )
            .dsTypography(.sub7)
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.top, .ds(.p10))
        .padding(.bottom, .ds(.p20))
    }

    /// 목록 — 행 사이 1pt 흰 틈이 그대로 구분선이 된다(시안 gap 1).
    private var reportList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(reports) { report in
                    if report.id == expandedReportID {
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
    private func expandedRow(_ report: Report) -> some View {
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
                onReportTapped?(report.id)
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

    /// 접힌 행 — 날짜만. 탭하면 펼친다.
    private func collapsedRow(_ report: Report) -> some View {
        Button {
            expandedReportID = report.id
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

// MARK: - 시안 값

extension HomeReportView.Report {
    /// 시안(3368:17266)의 목록 5행 — 리듀서가 목록을 들기 전까지의 기본값.
    static let placeholders: [Self] = [
        .init(dateText: "7월 11일 월", title: "캐시 도입 결정의 이유와 한계까지 구체적인 수치로 설명해 주셨어요"),
        .init(dateText: "7월 10일 월", title: "질문 의도를 되묻고 답변 범위를 좁혀 나갔어요"),
        .init(dateText: "7월 10일 월", title: "경험을 시간순으로 정리해 전달했어요"),
        .init(dateText: "7월 10일 월", title: "트레이드오프를 먼저 말하고 선택 이유를 덧붙였어요"),
        .init(dateText: "7월 10일 월", title: "성능 개선 결과를 지표로 설명했어요")
    ]
}

// MARK: - Previews

#Preview("HomeReport — 인사 문구 표시") {
    NavigationStack {
        HomeReportView(isGreetingVisible: true)
    }
}

#Preview("HomeReport — 인사 문구 숨김") {
    NavigationStack {
        HomeReportView(isGreetingVisible: false)
    }
}
