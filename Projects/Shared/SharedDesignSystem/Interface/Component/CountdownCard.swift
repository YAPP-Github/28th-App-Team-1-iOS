//
//  CountdownCard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/30.
//

import SwiftUI

/// 남은 시간을 세는 다크 카드 — Figma «countdown-card» 3165:14623 (`property1` 축 2종).
///
/// b800 판 위 두 줄: 제목 + 오른쪽 쉐브론 / g700 구분선 / 스톱워치 + 보조 문구 + 오른쪽 시간(22pt).
/// `.active` 는 흰 글자 + 그린 스톱워치(3165:14137) · `.ended` 는 g300 글자 + 회색 스톱워치(3165:14187).
///
/// **탭은 이 타입이 갖지 않는다** — 쉐브론이 가리키는 이동은 화면마다 목적지가 다르고
/// 상태에 따른 시각 변화가 없어서 규칙이 없다. 필요하면 호출부가 통째로 감싼다:
/// `Button { … } label: { CountdownCard(…) }.buttonStyle(.plain)`.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct CountdownCard: View {
    /// Figma `property1` 축. 시간이 흐르는 중인가 끝났는가 — 글자·아이콘 색이 함께 움직인다.
    public enum Status: Sendable, CaseIterable {
        /// 진행 중 — 흰 제목·시간 + 그린 스톱워치 (Figma `property1=active`)
        case active
        /// 종료 — g300 제목·시간 + 회색 스톱워치 (Figma `property1=end`)
        case ended
    }

    private let title: String
    private let subtitle: String
    private let time: String
    private let status: Status

    /// - Parameters:
    ///   - title: 첫 줄 제목. 폭이 모자라면 여러 줄로 흐른다(말줄임 없음).
    ///   - subtitle: 스톱워치 옆 보조 문구.
    ///   - time: 오른쪽 시간 표기 — 형식(`00:00:00`)은 호출부가 만든다.
    ///   - status: Figma `property1` 축.
    public init(title: String, subtitle: String, time: String, status: Status = .active) {
        self.title = title
        self.subtitle = subtitle
        self.time = time
        self.status = status
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p10)) {
            titleRow
            divider
            timeRow
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.HilitBlack.b800)
    }

    /// 제목 + 오른쪽 쉐브론. 시안에 둘 사이 간격이 없어(양끝 정렬) spacing 0.
    private var titleRow: some View {
        HStack(spacing: 0) {
            Text(title)
                // 상태마다 제목 타이포가 다르다 — 시안 그대로(파일 하단 불일치 주석 참조).
                .dsTypography(status == .active ? .body2 : .sub7)
                .foregroundStyle(primaryForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
            chevron
                .resizable()
                .scaledToFit()
                .frame(width: Metric.chevronSide, height: Metric.chevronSide)
        }
    }

    /// 두 줄을 가르는 1pt 선. 모서리 0 — 캡슐이 아니다.
    private var divider: some View {
        Rectangle()
            .fill(Color.GrayScale.g700)
            .frame(height: .ds(.small))
    }

    /// 스톱워치 + 보조 문구 / 오른쪽 시간.
    private var timeRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: .ds(.p8)) {
                timerIcon
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.timerSide, height: Metric.timerSide)
                Text(subtitle)
                    .dsTypography(.body9)
                    .foregroundStyle(Color.countdownSubtitle)
                    .opacity(Metric.subtitleOpacity)
            }
            Spacer(minLength: .ds(.p8))
            Text(time)
                .dsTypography(.sub3)
                .foregroundStyle(primaryForeground)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    /// 제목·시간이 공유하는 글자색.
    private var primaryForeground: Color {
        switch status {
        case .active: Color.BlackWhite.white
        case .ended: Color.GrayScale.g300
        }
    }

    private var chevron: Image {
        switch status {
        case .active: Image.Right.gray16
        case .ended: Image.Right.disabled16
        }
    }

    private var timerIcon: Image {
        switch status {
        case .active: Image.Timer.green24
        case .ended: Image.Timer.disabled24
        }
    }

    private enum Metric {
        /// 쉐브론 한 변 16 — Figma `right/16px`.
        static let chevronSide: CGFloat = 16
        /// 스톱워치 한 변 24 — Figma `timer/24px`.
        static let timerSide: CGFloat = 24
        /// 보조 문구 불투명도 80% — 시안 값. 두 상태 공통이라 축으로 열지 않는다.
        static let subtitleOpacity: Double = 0.8
    }
}

private extension Color {
    /// 보조 문구 색 #D2D6DE — 팔레트 23색 밖(g200 #BCBEC6 보다 밝다). Figma 변수명이
    /// `Gray scale/300` 인데 팔레트의 `grayscale/gray-300` 은 #9DA0AC 로 값이 다르다 —
    /// 어느 쪽이 맞는지 디자이너 확인 전까지 승격 보류.
    static let countdownSubtitle = Color(red: 210 / 255, green: 214 / 255, blue: 222 / 255)
}

// MARK: - Figma 원본 불일치
//
// 제목 타이포가 상태마다 다르다 — `active` 는 `body2_sb_16`, `end` 는 `sub7_sb_18`.
// 같은 카드에서 상태만 바뀌는데 글자 크기가 2pt 커질 이유가 없어 실수로 보이지만,
// 시안대로 구현했다(디자이너 확인 대기).

#Preview {
    VStack(alignment: .leading, spacing: .ds(.p20)) {
        CountdownCard(title: "title", subtitle: "sub-title", time: "00:00:00")
        CountdownCard(title: "title", subtitle: "sub-title", time: "00:00:00", status: .ended)
        CountdownCard(
            title: "아주 긴 제목이라서 한 줄에 들어가지 않고 다음 줄로 흘러야 하는 경우를 확인한다",
            subtitle: "면접 종료까지",
            time: "01:23:45"
        )
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity)
    .background(Color.GrayScale.g50)
}
