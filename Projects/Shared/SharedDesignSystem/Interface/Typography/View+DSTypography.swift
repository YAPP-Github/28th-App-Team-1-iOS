//
//  View+DSTypography.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/18.
//

import SwiftUI
import UIKit

public extension View {
    /// 타이포 토큰의 폰트·행간·자간을 일괄 적용한다 — Figma 스펙과 1:1 이 필요한 기본 진입점.
    /// (`.font(.ds(…))` 단독 사용은 행간·자간이 빠지므로 특수한 경우에만)
    func dsTypography(_ typography: DSTypography) -> some View {
        modifier(DSTypographyModifier(typography: typography))
    }
}

private struct DSTypographyModifier: ViewModifier {
    let typography: DSTypography

    func body(content: Content) -> some View {
        // SwiftUI 에 line-height 개념이 없어 표준 보정을 쓴다:
        // 목표 행간과 폰트 고유 행간의 차를 lineSpacing(줄 사이) + 상하 패딩(단일 줄 박스 높이)으로 분배.
        let extraLeading = max(0, typography.lineHeight - typography.intrinsicLineHeight)
        content
            .font(.ds(typography))
            .tracking(typography.letterSpacing)
            .lineSpacing(extraLeading)
            .padding(.vertical, extraLeading / 2)
    }
}

private extension DSTypography {
    /// 렌더링 폰트의 고유 행간. 생성 접근자가 미등록 시 등록까지 처리하므로 별도 부트스트랩이 없다.
    var intrinsicLineHeight: CGFloat { weight.asset.font(size: size).lineHeight }
}
