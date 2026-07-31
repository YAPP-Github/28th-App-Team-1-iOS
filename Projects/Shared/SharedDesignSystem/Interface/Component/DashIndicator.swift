//
//  DashIndicator.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

import SwiftUI

/// 진행 단계 표시용 대시 인디케이터 — Figma «dash» 2044:4712(on/off) 를 나열한 형태.
/// 조각 하나는 높이 4 사각(모서리 0) — 켜짐 b800 / 꺼짐 g50.
/// 조각 자체는 «bool → 색» 뿐이라 공개 타입을 주지 않고, «몇 번째까지 켜는가» 규칙을 갖는 이 묶음만 공개한다.
/// 폭·간격은 `Layout` 축이 정한다 — 두 변형이 시안에서 확인됐다(가입 온보딩 3877:11573·11580·11601 / dash 2044:4712).
public struct DashIndicator: View {
    /// 조각 폭 축 — 시안에 두 변형이 실재한다. 빼먹으면 조용히 다른 룩이 나오므로 기본값은 좁은 쪽(`.hug`).
    public enum Layout: Sendable {
        /// 20pt 고정폭 · 간격 4 — dash 2044:4712 원형.
        case hug
        /// 주어진 폭을 단계 수만큼 등분 · 간격 2 — 가입 온보딩 진행 바.
        case fill
    }

    private let count: Int
    private let current: Int
    private let layout: Layout

    /// - Parameters:
    ///   - count: 전체 단계 수.
    ///   - current: 현재 단계(1-based). 이 값까지 켜진다. 범위를 넘으면 잘라낸다.
    ///   - layout: 조각 폭·간격 규칙. 좌우 여백은 호출부 몫이다.
    public init(count: Int, current: Int, layout: Layout = .hug) {
        self.count = count
        self.current = current
        self.layout = layout
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                dash(isOn: index < current)
            }
        }
    }

    @ViewBuilder private func dash(isOn: Bool) -> some View {
        let shape = Rectangle().fill(isOn ? Color.HilitBlack.b800 : Color.GrayScale.g50)
        switch layout {
        case .hug: shape.frame(width: 20, height: 4)
        case .fill: shape.frame(maxWidth: .infinity).frame(height: 4)
        }
    }

    // @ds(spacing): 2 — `.fill` 조각 간격. DSSpacing 은 Figma padding 스케일 1:1(4 부터)이라 토큰 없음
    private var spacing: CGFloat {
        switch layout {
        case .hug: .ds(.p4)
        case .fill: 2
        }
    }
}

#Preview("hug — dash 원형") {
    VStack(spacing: .ds(.p20)) {
        DashIndicator(count: 4, current: 1)
        DashIndicator(count: 4, current: 3)
        DashIndicator(count: 4, current: 4)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}

#Preview("fill — 가입 온보딩 진행 바") {
    VStack(spacing: .ds(.p20)) {
        DashIndicator(count: 3, current: 1, layout: .fill)
        DashIndicator(count: 3, current: 2, layout: .fill)
        DashIndicator(count: 3, current: 3, layout: .fill)
    }
    .padding(.horizontal, .ds(.p20))
    .padding(.vertical, .ds(.p4))
    .background(Color.BlackWhite.white)
}
