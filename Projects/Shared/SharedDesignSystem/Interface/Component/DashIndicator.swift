//
//  DashIndicator.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

import SwiftUI

/// 진행 단계 표시용 대시 인디케이터 — Figma «dash» 2044:4712(on/off) 를 나열한 형태.
/// 조각 하나는 20×4 사각(모서리 0) — 켜짐 b800 / 꺼짐 g50.
/// 조각 자체는 «bool → 색» 뿐이라 공개 타입을 주지 않고, «몇 번째까지 켜는가» 규칙을 갖는 이 묶음만 공개한다.
/// 간격 4 는 시안에서 확인되지 않은 가정 — 사용 화면 노드가 나오면 대조한다.
public struct DashIndicator: View {
    private let count: Int
    private let current: Int

    /// - Parameters:
    ///   - count: 전체 단계 수.
    ///   - current: 현재 단계(1-based). 이 값까지 켜진다. 범위를 넘으면 잘라낸다.
    public init(count: Int, current: Int) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        HStack(spacing: .ds(.p4)) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                Rectangle()
                    .fill(index < current ? Color.HilitBlack.b800 : Color.GrayScale.g50)
                    .frame(width: 20, height: 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: .ds(.p20)) {
        DashIndicator(count: 4, current: 1)
        DashIndicator(count: 4, current: 3)
        DashIndicator(count: 4, current: 4)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
