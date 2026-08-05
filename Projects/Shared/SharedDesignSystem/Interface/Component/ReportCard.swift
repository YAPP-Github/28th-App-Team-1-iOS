//
//  ReportCard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «report-card-open» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=439-9750
//        «report-card-close» 439:9758

import SwiftUI

/// 리포트 목록 줄 — Figma «report-card-open» 439:9750 · «report-card-close» 439:9758.
///
/// `.open` 은 b800 판(px20·py24) 위 «날짜 / 타이틀 / 오른쪽 그린 사각 화살표»,
/// `.close` 는 연한 그린 띠(p20) 위 날짜 한 줄. 접힌 줄에는 타이틀이 없어서 payload 가 케이스에 붙는다.
///
/// 시안은 **두 개의 독립 컴포넌트**(variant set 아님)인데 같은 목록의 펼침·접힘 상태라 한 타입으로 합쳤다.
///
/// **탭은 이 타입이 갖지 않는다** — 화살표가 가리키는 이동 목적지가 화면마다 다르다(`CountdownCard`
/// 와 같은 판단). 호출부가 통째로 감싼다: `Button { … } label: { ReportCard(…) }.buttonStyle(.plain)`.
/// 좌우 여백이 판 안(px20)에 있어 **화면 폭을 그대로 채우는** 줄이다 — 콘텐츠 열에 넣지 않는다.
public struct ReportCard: View {
    /// 펼침·접힘 축. 접힌 줄엔 타이틀이 없다.
    public enum Status: Sendable, Equatable {
        /// 펼침 — b800 판 + 타이틀 + 그린 화살표 (Figma «report-card-open»)
        case open(title: String)
        /// 접힘 — 연한 그린 띠 + 날짜 한 줄 (Figma «report-card-close»)
        case close
    }

    private let date: String
    private let status: Status

    /// - Parameters:
    ///   - date: 날짜 표기 — 형식(`0월 0일 월`)은 호출부가 만든다.
    ///   - status: 펼침·접힘 축.
    public init(date: String, status: Status) {
        self.date = date
        self.status = status
    }

    public var body: some View {
        switch status {
        case let .open(title):
            openBody(title: title)
        case .close:
            closeBody
        }
    }

    /// 펼친 줄 — 글자 열은 왼쪽 정렬, 화살표만 오른쪽으로 밀린다(시안 `items-end`).
    private func openBody(title: String) -> some View {
        VStack(alignment: .trailing, spacing: .ds(.p16)) {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                Text(date)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.HilitGreen.g500)
                Text(title)
                    .dsTypography(.sub4)
                    .foregroundStyle(Color.BlackWhite.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            arrowBadge
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p24))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.HilitBlack.b800)
    }

    /// 그린 사각 안 화살표 — p10 여백이 24pt 아이콘을 44pt 판으로 키운다. 모서리 0.
    private var arrowBadge: some View {
        Image.Right.default24
            .resizable()
            .scaledToFit()
            .frame(width: Metric.arrowSide, height: Metric.arrowSide)
            .padding(.ds(.p10))
            .background(Color.HilitGreen.g500)
    }

    private var closeBody: some View {
        Text(date)
            .dsTypography(.body3)
            .foregroundStyle(Color.reportCardClosedText)
            .padding(.ds(.p20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.reportCardClosedSurface)
    }

    private enum Metric {
        /// 화살표 한 변 24 — Figma `right/24px/default`. 화살표는 b800 이 에셋에 구워져 있다.
        static let arrowSide: CGFloat = 24
    }
}

private extension Color {
    /// 접힌 줄 판 색 #D2EFCC — Figma 변수 `hilit green/200`. 팔레트 23색에 그린은 g500·g600·g800
    /// 뿐이라 이름 붙은 변수인데도 대응 토큰이 없다. **팔레트 공백** 이라 승격 후보로 남기고
    /// (Colors.xcassets 에 `ColorD2EFCC` + `HilitGreen.g200`) 그때까지 파일 내부 상수로 둔다.
    static let reportCardClosedSurface = Color(red: 210 / 255, green: 239 / 255, blue: 204 / 255)

    /// 접힌 줄 글자색 #0A1C1F — Figma 에서 변수에 묶이지 않은 raw 값이다. 가장 가까운 팔레트 색
    /// `b900`(#121316)과 채널마다 8~9 차이라 근사 범위(≈2/255) 밖 — 승격 보류
    /// (`CountdownCard` 의 #D2D6DE 와 같은 처리).
    static let reportCardClosedText = Color(red: 10 / 255, green: 28 / 255, blue: 31 / 255)
}

// MARK: - Figma 원본 불일치
//
// ① `.open` 타이틀은 텍스트 스타일 변수에 묶이지 않은 raw 값이다 — SemiBold 20 / 행간 140%(28) /
//    자간 -2.5%. 20pt 층 토큰 `sub4`(sb 20)는 행간 130%(26) 라 2pt 좁다. 토큰 우선 원칙대로
//    `sub4` 를 썼다(디자이너 확인 대기). 날짜(`body3_m_16`)는 두 변형 모두 변수에 제대로 묶여 있다.
// ② `.close` 는 판 색이 팔레트 밖(`hilit green/200`)이고 글자색은 변수조차 없다 — 위 Color 확장 주석 참조.

#Preview("report-card") {
    VStack(spacing: .ds(.p20)) {
        ReportCard(date: "0월 0일 월", status: .open(title: "title"))
        ReportCard(date: "0월 0일 월", status: .close)
        ReportCard(
            date: "7월 31일 목",
            status: .open(title: "아주 긴 리포트 제목이라서 한 줄에 들어가지 않고 다음 줄로 흘러야 하는 경우를 확인한다")
        )
    }
    .frame(maxWidth: .infinity)
    .background(Color.HilitBlack.b900)
}
