//
//  LoadingModal.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «modal/loading» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-1543
// 페이지 인스턴스 439:10407 (Component System 3, 439:10241).

import SwiftUI

/// 로딩 모달 카드 — 170 정사각 흰 판 가운데 74pt 스피너 링.
///
/// ```swift
/// .hilitModal(isPresented: store.isGenerating) { LoadingModal() }
/// ```
///
/// **`.hilitButtonLoading` 과 다른 물건이다.** 그쪽은 버튼 안에서 라벨을 감추고 겹치는
/// 버튼 스코프 오버레이이고 시안에 없다. 이건 화면 전체를 막는 모달 카드로 시안에 실재한다
/// (435:1543). 둘을 합치면 스코프가 섞여 «버튼 없는 로딩»·«모달 없는 버튼»이 표현 불가능해진다.
///
/// 텍스트·취소 버튼 슬롯 없음 — 시안이 링 하나로 닫혀 있다. 문구가 필요해지면 시안을 먼저 받는다.
/// 딤 배경·표시 전환은 `.hilitModal` 오버레이 몫 — 이 타입은 판만 그린다. 판이 정사각 고정폭이라
/// 오버레이의 좌우 여백 24 는 무해하다(카드가 그보다 좁다).
public struct LoadingModal: View {
    public init() {}

    public var body: some View {
        SpinnerRing()
            .frame(width: Metric.ringSide, height: Metric.ringSide)
            .frame(width: Metric.surfaceSide, height: Metric.surfaceSide)
            .background(Color.BlackWhite.white)
    }

    private enum Metric {
        /// 흰 판 한 변 170 — 시안 고정값. 링 74 를 감싸 사방 48 여백이 된다.
        static let surfaceSide: CGFloat = 170
        /// 링 한 변 74 — 시안 프레임 435:1544. 안쪽 벡터는 72.0×73.0 인데(디자이너 타원 오차)
        /// 74 슬롯에 맞춰 정원으로 정규화했다. 다른 모달의 일러스트 슬롯과 같은 74.
        static let ringSide: CGFloat = 74
    }
}

/// 스피너 링 — b800 전체 링 위에 g500 호가 3시 방향부터 시계방향으로 얹히고, 전체가 회전한다.
///
/// 링 자체는 시안 벡터(`Ellipse 1084`/`1085`)와 1:1 이지만 **회전은 시안에 없다** — 정지 이미지로
/// 두면 로딩으로 안 읽혀서 코드가 준다. 에셋으로 받지 않는 이유도 이것(회전은 어차피 코드 몫이고,
/// `Image.Loading` 패밀리엔 16·24 판만 있어 74 짜리가 없다).
private struct SpinnerRing: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.HilitBlack.b800, lineWidth: Metric.stroke)
            // `stroke` 는 경로 중앙에 그려지므로 `strokeBorder`(안쪽) 와 맞추려 반두께만큼 들인다.
            Circle()
                .trim(from: 0, to: Metric.greenTurn)
                .stroke(Color.HilitGreen.g500, lineWidth: Metric.stroke)
                .padding(Metric.stroke / 2)
        }
        .rotationEffect(.degrees(isSpinning ? 360 : 0))
        .animation(.linear(duration: Metric.turnDuration).repeatForever(autoreverses: false), value: isSpinning)
        .onAppear { isSpinning = true }
    }

    private enum Metric {
        /// 링 두께 10 — 시안 `stroke-width: 10`. outline 토큰 스케일(1~6)을 벗어나 여기 상수로 둔다.
        static let stroke: CGFloat = 10
        /// 그린 호가 도는 비율 — 시안 실측 110.7°(3시 → 시계방향) ≈ 0.31 바퀴.
        static let greenTurn: CGFloat = 0.31
        /// 한 바퀴 도는 시간 — 시안에 모션 스펙이 없어 정한 값.
        static let turnDuration: TimeInterval = 1
    }
}

// MARK: - Previews

#Preview("modal/loading — 439:10407") {
    LoadingModal()
        .padding(.ds(.p24))
        .background(Color.HilitBlack.b900.opacity(0.5))
}

#Preview("오버레이 표출") {
    Text("배경 화면")
        .dsTypography(.body2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.GrayScale.g50)
        .hilitModal(isPresented: true) {
            LoadingModal()
        }
}
