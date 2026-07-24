//
//  Parallelogram.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 하이라이트 배경용 평행사변형 — Figma `highlighted-text` 컴포넌트 1:1.
/// 윗변이 `slant`(기본 4pt)만큼 오른쪽으로 밀린 형태로, 높이와 무관하게 기울기 오프셋은 고정이다
/// (Figma 좌우 변 SVG: 높이 27·21 모두 수평 오프셋 4). 텍스트 하이라이트·라벨 칩 공용.
///
/// 사용: 콘텐츠에 `.padding(.horizontal, .ds(.p8))` 후 `.background(색, in: Parallelogram())` —
/// Figma 가 텍스트 양옆에 8pt(경사 4 + 평면 4) 여백을 두므로 p8 미만이면 글자가 경사면에 닿는다.
public struct Parallelogram: Shape {
    private let slant: CGFloat

    public init(slant: CGFloat = 4) {
        self.slant = slant
    }

    public func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + slant, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - slant, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("피드백")
            .padding(.horizontal, 8)
            .background(Color.HilitGreen.g500, in: Parallelogram())
        Text("잘 맞춤")
            .foregroundStyle(Color.Positive.p800)
            .padding(.horizontal, 8)
            .background(Color.Positive.p200, in: Parallelogram())
    }
    .padding()
}
