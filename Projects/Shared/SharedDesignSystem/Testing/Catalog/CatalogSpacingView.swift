//
//  CatalogSpacingView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// Spacing · Outline 토큰 — 둘 다 `CaseIterable` 이라 순회한다.
/// 값(`value`)은 공개라 눈금과 숫자를 같이 보여줄 수 있다.
struct CatalogSpacingView: View {
    var body: some View {
        CatalogPage("Spacing · Outline") {
            CatalogGroup("DSSpacing — .padding(.ds(.p20))") {
                VStack(alignment: .leading, spacing: .ds(.p8)) {
                    ForEach(DSSpacing.allCases, id: \.self) { spacing in
                        HStack(spacing: .ds(.p8)) {
                            Text(".\(label(of: spacing))")
                                .dsTypography(.body9)
                                .foregroundStyle(Color.GrayScale.g700)
                                .frame(width: 40, alignment: .leading)
                            Rectangle()
                                .fill(Color.HilitGreen.g500)
                                .frame(width: spacing.value, height: 12)
                            Text("\(Int(spacing.value))")
                                .dsTypography(.body9)
                                .foregroundStyle(Color.GrayScale.g400)
                        }
                    }
                }
            }

            CatalogGroup("DSOutline — .strokeBorder(…, lineWidth: .ds(.medium))") {
                VStack(alignment: .leading, spacing: .ds(.p8)) {
                    ForEach(DSOutline.allCases, id: \.self) { outline in
                        HStack(spacing: .ds(.p8)) {
                            Text(".\(label(of: outline))")
                                .dsTypography(.body9)
                                .foregroundStyle(Color.GrayScale.g700)
                                .frame(width: 60, alignment: .leading)
                            Rectangle()
                                .fill(Color.BlackWhite.white)
                                .frame(width: 120, height: 32)
                                .overlay {
                                    Rectangle()
                                        .strokeBorder(Color.HilitBlack.b800, lineWidth: outline.value)
                                }
                            Text(trimmed(outline.value))
                                .dsTypography(.body9)
                                .foregroundStyle(Color.GrayScale.g400)
                        }
                    }
                }
            }
        }
    }

    /// `CustomStringConvertible` 가 없어 리플렉션 문자열을 쓴다 — 카탈로그 전용이라 이 정도면 충분하다.
    private func label(of value: Any) -> String { String(describing: value) }

    private func trimmed(_ value: CGFloat) -> String {
        value == value.rounded() ? "\(Int(value))" : "\(value)"
    }
}

#Preview {
    NavigationStack { CatalogSpacingView() }
}
