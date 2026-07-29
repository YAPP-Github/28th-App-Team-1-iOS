//
//  SaveIndicator.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 자동 저장 상태 표시 — Figma «tag-with-icon»(node 2555:7558) 1:1.
/// 저장 중=그린 스피너 + «저장 중 ...», 저장됨=그린 체크 + «저장됨».
/// 텍스트는 gray/500 SemiBold12(.body8). 미저장(표시 없음)은 호출부가 뷰 자체를 숨긴다.
public struct SaveIndicator: View {
    public enum Status: Sendable {
        case saving
        case saved
    }

    private let status: Status

    public init(_ status: Status) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: .ds(.p4)) {
            switch status {
            case .saving:
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.HilitGreen.g500)
                label("저장 중 ...")
            case .saved:
                Image(systemName: "checkmark.circle.fill")
                    .font(.ds(.body2))   // 16pt 아이콘 — 토큰 사이징
                    .foregroundStyle(Color.HilitGreen.g500)
                label("저장됨")
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .dsTypography(.body8)
            .foregroundStyle(Color.GrayScale.g500)
    }
}

#Preview {
    VStack(spacing: .ds(.p12)) {
        SaveIndicator(.saving)
        SaveIndicator(.saved)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
