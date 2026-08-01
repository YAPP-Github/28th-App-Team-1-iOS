//
//  CameraGuideFrame.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/25.
//

import SwiftUI

/// 카메라 위 얼굴 맞춤 가이드 — Figma «camera-frame» 435:821 (`showText` × `text` 프로퍼티).
///
/// 327pt 정방형. 네 모서리 L자 브래킷(팔 37.5 · 두께 5, 좌상단만 g300 나머지 g200) +
/// 중앙 안내 문구(`head4` g400, p24). 에셋 없이 코드 드로잉이다 — 브래킷이 단순 선이라
/// 크기·색을 코드에서 잡는 편이 크기별 재수출보다 싸다.
///
/// 문구는 열린 파라미터다 — 시안 기본값은 «텍스트를 입력해주세요»(placeholder)고, 실제 문구는
/// 화면이 넘긴다. Figma `showText` 축은 별도 Bool 로 두지 않고 **`text` 의 유무**로 표현한다
/// (`Modal`·`TitleBox` 의 `show*` 축 처리와 같은 규칙).
///
/// **`blendsColorBurn` 은 기본 꺼져 있다** — 시안은 브래킷·문구에 `mix-blend color-burn` 을
/// 걸어 카메라 영상 위에 눌러 얹는다. 그런데 이 가이드가 얹히는 카메라 프리뷰는
/// `AVCaptureVideoPreviewLayer`(UIKit 호스팅 레이어)라, SwiftUI 블렌드 모드가 그 레이어를
/// backdrop 으로 삼지 못한다 — 투명 배경에 color-burn 이 걸려 새까맣게 될 수 있다.
/// 실기기에서 육안 확인이 끝나기 전엔 켜지 않는다(lat.md interview#프리뷰).
/// 폭·위치는 호출부 몫 — 327 정방형은 이 뷰가 고정하고, 화면 안 어디에 놓을지는 화면이 정한다.
public struct CameraGuideFrame: View {
    private let text: String?
    private let blendsColorBurn: Bool

    /// - Parameters:
    ///   - text: 중앙 안내 문구. `nil`(기본)이면 브래킷만 그린다 — Figma `showText=false`.
    ///   - blendsColorBurn: 시안의 `mix-blend color-burn` 적용 여부. 기본 `false`(원색 그대로) —
    ///     카메라 프리뷰가 UIKit 레이어라 블렌드가 성립하는지 실기기 확인 전이다.
    public init(text: String? = nil, blendsColorBurn: Bool = false) {
        self.text = text
        self.blendsColorBurn = blendsColorBurn
    }

    public var body: some View {
        ZStack {
            bracket(Color.GrayScale.g300, rotation: 0, alignment: .topLeading)
            bracket(Color.GrayScale.g200, rotation: 90, alignment: .topTrailing)
            bracket(Color.GrayScale.g200, rotation: 180, alignment: .bottomTrailing)
            bracket(Color.GrayScale.g200, rotation: 270, alignment: .bottomLeading)

            if let text {
                Text(text)
                    .dsTypography(.head4)
                    .foregroundStyle(Color.GrayScale.g400)
                    .multilineTextAlignment(.center)
                    .padding(.ds(.p24))
            }
        }
        .frame(width: Metric.side, height: Metric.side)
        // 브래킷·문구를 한 덩어리로 묶어 블렌드한다 — 낱개로 걸면 서로를 backdrop 삼아 겹친다.
        .compositingGroup()
        .blendMode(blendsColorBurn ? .colorBurn : .normal)
    }

    private func bracket(_ color: Color, rotation: Double, alignment: Alignment) -> some View {
        CornerBracketShape()
            .stroke(color, lineWidth: CornerBracketShape.thickness)
            .frame(width: CornerBracketShape.arm, height: CornerBracketShape.arm)
            .rotationEffect(.degrees(rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    private enum Metric {
        /// 한 변 327 — Figma 프레임 크기.
        static let side: CGFloat = 327
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

#Preview("브래킷 + 문구") {
    CameraGuideFrame(text: "텍스트를 입력해주세요")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.GrayScale.g900)
}

#Preview("브래킷만") {
    CameraGuideFrame()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.GrayScale.g900)
}

#Preview("color-burn 블렌드") {
    CameraGuideFrame(text: "텍스트를 입력해주세요", blendsColorBurn: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.GrayScale.g50)
}
