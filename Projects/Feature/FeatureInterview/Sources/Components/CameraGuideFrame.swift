//
//  CameraGuideFrame.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import SharedDesignSystemInterface
import SwiftUI

/// Figma «camera-frame»(2479:7555) — 327pt 정방형 얼굴 맞춤 가이드. 네 모서리 L자 브래킷
/// (팔 길이 37.5 · 두께 5, TL 만 gray-300 나머지 gray-200) + 중앙 안내 문구.
/// 원본은 mix-blend color-burn 으로 카메라 위에 얹힌다 — 프리뷰 배선 전이라 블렌드는 보류하고
/// 원색 그대로 그린다 (카메라 도입 시 재검토). 준비·세션 진행 화면이 공유한다.
struct CameraGuideFrame: View {
    var showsCenterText = false

    private static let side: CGFloat = 327

    var body: some View {
        ZStack {
            bracket(Color.GrayScale.g300, rotation: 0, alignment: .topLeading)
            bracket(Color.GrayScale.g200, rotation: 90, alignment: .topTrailing)
            bracket(Color.GrayScale.g200, rotation: 180, alignment: .bottomTrailing)
            bracket(Color.GrayScale.g200, rotation: 270, alignment: .bottomLeading)

            if showsCenterText {
                Text("얼굴을 여기에 맞춰주세요")
                    .dsTypography(.head4)
                    .foregroundStyle(Color.GrayScale.g400)
                    .multilineTextAlignment(.center)
                    .padding(.ds(.p24))
            }
        }
        .frame(width: Self.side, height: Self.side)
    }

    private func bracket(_ color: Color, rotation: Double, alignment: Alignment) -> some View {
        CornerBracketShape()
            .stroke(color, lineWidth: CornerBracketShape.thickness)
            .frame(width: CornerBracketShape.arm, height: CornerBracketShape.arm)
            .rotationEffect(.degrees(rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

/// 좌상단 방향 L자 브래킷 — SVG «M37.5 2.5H2.5V37.5» (팔 37.5 · 스트로크 5) 재현.
/// 회전으로 네 모서리에 재사용한다.
private struct CornerBracketShape: Shape {
    static let arm: CGFloat = 37.5
    static let thickness: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        let inset = Self.thickness / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        return path
    }
}

#Preview {
    CameraGuideFrame(showsCenterText: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.GrayScale.g900)
}
