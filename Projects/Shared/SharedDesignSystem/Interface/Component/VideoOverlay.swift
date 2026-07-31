//
//  VideoOverlay.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

import SwiftUI

/// 영상 위 아래쪽 그라디언트 스크림 — Figma «video overlay» (`mood` × `status` 축).
///
/// 위가 투명, 아래가 불투명한 세로 램프. 영상·카메라 프리뷰 위에 얹혀 하단 컨트롤·자막의
/// 가독성을 만든다. 탭을 먹지 않는다(`allowsHitTesting(false)` 내장) — 스크림 뒤 컨트롤이 살아야 한다.
///
/// Figma 축은 `mood`(dark/light) × `status`(open/close) 인데 **light/open 은 실재하지 않는다** —
/// 존재하는 3조합만 `Variant` 케이스로 닫았다(2축 곱으로 열면 없는 조합이 만들어진다, 사고 사례 5번).
///
/// 높이는 램프 «모양»과 분리한다 — 스톱 위치가 비율이라 어느 높이에서도 시안 곡선이 유지된다.
/// 시안 높이가 기본값이고, 화면 실측이 있으면 `height:` 로 덮는다(스크림이 덮는 범위는 화면 몫).
public struct VideoOverlay: View {
    /// Figma `mood` × `status` 중 실재하는 3조합.
    public enum Variant: Sendable, CaseIterable {
        /// 다크 · 펼침 — 435:847 (375×523, 3스톱). 컨트롤·카드가 다 보이는 상태의 긴 램프.
        case darkOpen
        /// 다크 · 접힘 — 435:845 (375×229, 2스톱). 짧은 램프.
        case darkClose
        /// 라이트 · 접힘 — 435:849 (375×76, 3스톱 흰색). 밝은 판 위 짧은 램프.
        case lightClose

        /// 시안 높이 — `height:` 를 안 넘겼을 때 쓰는 기본값.
        public var designedHeight: CGFloat {
            switch self {
            case .darkOpen: 523
            case .darkClose: 229
            case .lightClose: 76
            }
        }

        /// 세로 램프 스톱 — 위(0) → 아래(1).
        var stops: [Gradient.Stop] {
            switch self {
            case .darkOpen:
                // rgba(18,19,22,0) → rgba(18,19,22,.56) @33.135% → #121316 @90.895%
                [
                    .init(color: Color.HilitBlack.b900.opacity(0), location: 0),
                    .init(color: Color.HilitBlack.b900.opacity(0.56), location: 0.33135),
                    .init(color: Color.HilitBlack.b900, location: 0.90895)
                ]
            case .darkClose:
                // rgba(18,19,22,0) → #121316 @91.542%
                [
                    .init(color: Color.HilitBlack.b900.opacity(0), location: 0),
                    .init(color: Color.HilitBlack.b900, location: 0.91542)
                ]
            case .lightClose:
                // rgba(255,255,255,0) → rgba(255,255,255,.4) @49.954% → white @109.21%.
                // 마지막 스톱이 프레임 밖(109.21%)이다 — SwiftUI 는 location 을 [0,1] 로 자르므로
                // 위치를 그대로 넘기면 흰색이 9% 일찍 도달해 아래끝이 시안보다 진해진다.
                // 위치를 자르는 대신 **100% 지점의 색을 보간해** 마지막 스톱으로 쓴다 — 램프가 그대로 남는다.
                // alpha(100%) = 0.4 + 0.6 × (100 − 49.954) / (109.21 − 49.954) ≈ 0.907
                [
                    .init(color: Color.BlackWhite.white.opacity(0), location: 0),
                    .init(color: Color.BlackWhite.white.opacity(0.4), location: 0.49954),
                    .init(color: Color.BlackWhite.white.opacity(0.907), location: 1)
                ]
            }
        }
    }

    private let variant: Variant
    private let height: CGFloat

    /// - Parameters:
    ///   - variant: Figma `mood` × `status` 조합.
    ///   - height: 스크림이 덮는 높이. `nil` 이면 시안 높이(`Variant.designedHeight`).
    ///     화면에서 실측한 노출부가 있으면 그 값을 넘긴다 — 램프 비율은 그대로 유지된다.
    public init(_ variant: Variant, height: CGFloat? = nil) {
        self.variant = variant
        self.height = height ?? variant.designedHeight
    }

    public var body: some View {
        LinearGradient(
            stops: variant.stops,
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        // 스크림은 언제나 장식이다 — 뒤에 깔린 컨트롤의 탭을 가로막지 않는다.
        .allowsHitTesting(false)
    }
}

#Preview("dark") {
    ZStack(alignment: .bottom) {
        Color.GrayScale.g600
        VideoOverlay(.darkOpen)
    }
    .ignoresSafeArea()
}

#Preview("dark / close") {
    ZStack(alignment: .bottom) {
        Color.GrayScale.g600
        VideoOverlay(.darkClose)
    }
    .ignoresSafeArea()
}

#Preview("light / close") {
    ZStack(alignment: .bottom) {
        Color.GrayScale.g600
        VideoOverlay(.lightClose)
    }
    .ignoresSafeArea()
}
