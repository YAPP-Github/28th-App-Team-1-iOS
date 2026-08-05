//
//  HomeGreenBackdrop.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: 홈 프레임 4종이 공유하는 장식 배경 노드 (3756:10789 ≡ 3632:10936)

import SharedDesignSystemInterface
import SwiftUI

/// 홈 그린 장식 배경 — g500 판 위에 세로 스트라이프(밴드) 8개를 겹친 «커튼/블라인드» 결.
/// 줄마다 다른 흰 세로 그라데이션이 얹혀 위·아래는 흰색으로 덮이고 가운데 띠만 그린이 비친다.
/// 상단이 흰색이라 내비바(흰 판)와 이음새가 없다.
///
/// 홈 4화면(기본·면접 시작·진행 중·리포트)이 같은 Figma 노드를 공유해 여기 하나로 둔다 —
/// 사용처가 FeatureHome 안뿐이라 DS 승격은 하지 않는다.
///
/// safe area 처리는 **호출부 몫**이다 — 화면마다 덮는 변이 달라(전체 / 하단만) 여기서 정하지 않는다.
// @ds(component): 세로 스트라이프 8줄 × 흰 그라데이션 정지점 — 홈 전용 장식 배경, DS 에 컴포넌트·토큰 없음
struct HomeGreenBackdrop: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.stripes.indices, id: \.self) { index in
                LinearGradient(
                    stops: Self.stripes[index].map {
                        Gradient.Stop(color: Color.BlackWhite.white.opacity($0.opacity), location: $0.location)
                    },
                    startPoint: .top,
                    endPoint: .bottom
                )
                // @ds(spacing): 0.2 — 스트라이프 경계선 두께 (DSOutline 최소가 1)
                .border(Color.BlackWhite.white, width: 0.2)
            }
        }
        .background(Color.HilitGreen.g500)
        .frame(maxWidth: .infinity)
        // 장식이라 탭을 먹지 않는다 — `.background {}` 로 깔리는 화면(리포트)에서도 앞 콘텐츠가 먼저 받는다.
        .allowsHitTesting(false)
    }

    /// 스트라이프별 흰색 그라데이션 정지점 — (흰색 불투명도, 위치). Figma 값을 반올림 없이 그대로 보존한다.
    /// `location` 은 화면 전체 높이 비율(시안 812pt 기준 %)이라 기기 높이가 달라도 같은 비율로 늘어난다.
    /// 줄마다 정지점이 달라 주름이 불규칙해 보인다 — 폭은 시안 46.875(= 375/8)를 고정하지 않고
    /// 8등분으로 둔다(기기 폭 대응).
    // @ds(color): white 알파 0.1~0.4 정지점 8종 — 스트라이프 그라데이션. 팔레트에 알파 단계 없음
    private static let stripes: [[(opacity: Double, location: CGFloat)]] = [
        [(1, 0.13556), (0.4, 0.32461), (1, 0.99998)],
        [(1, 0.11453), (0.4, 0.25734), (0.3, 0.47496), (0.4, 0.58866), (1, 1)],
        [(1, 0.11788), (0.4, 0.23104), (0.2, 0.39393), (0.1, 0.504), (0.4, 0.68435), (1, 1)],
        [(1, 0.117), (0.3, 0.23357), (0.1, 0.31717), (0.1, 0.39739), (0.3, 0.68805), (1, 1)],
        [(1, 0.13308), (0.3, 0.24422), (0.1, 0.39291), (0.1, 0.50844), (0.3, 0.62571), (1, 1)],
        [(1, 0.1221), (0.4, 0.2742), (0.2, 0.37483), (0.1, 0.5122), (0.4, 0.68957), (1, 1)],
        [(1, 0.14222), (0.4, 0.32786), (0.3, 0.42853), (0.4, 0.5898), (1, 1)],
        [(1, 0.14044), (0.4, 0.51272), (1, 0.99998)]
    ]
}

#Preview("홈 그린 배경") {
    HomeGreenBackdrop()
        .ignoresSafeArea()
}
