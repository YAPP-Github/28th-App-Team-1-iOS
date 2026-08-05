//
//  HilitDivider.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

import SwiftUI

/// 구분선 한 줄 — Figma «divider» 435:828 (335×1, g800).
///
/// 이름에 `Hilit` 을 붙인 이유는 SwiftUI 에 이미 `Divider` 가 있어서다 — 같은 이름을 쓰면
/// import 순서에 따라 어느 쪽이 잡히는지 호출부에서 안 보인다(`HilitTextField` 와 같은 이유).
///
/// **다크 판 전제** — g800(#31333B)은 거의 검정 회색이라 흰 판 위에서는 실선처럼 무겁다.
/// 밝은 판의 구분선은 이 토큰이 아니다(예: `CountdownCard` 의 b800 판 안 선은 g700).
/// 시안이 어느 화면에서 쓰이는지 적어두지 않았다 — 라이트 판 변형이 필요해지면 축을 열기 전에
/// 디자이너에게 확인한다.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct HilitDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.GrayScale.g800)
            .frame(height: .ds(.small))
    }
}

#Preview {
    VStack(spacing: .ds(.p20)) {
        HilitDivider()
        Text("두 줄 사이")
            .dsTypography(.body6)
            .foregroundStyle(Color.BlackWhite.white)
        HilitDivider()
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity)
    .background(Color.HilitBlack.b900)
}
