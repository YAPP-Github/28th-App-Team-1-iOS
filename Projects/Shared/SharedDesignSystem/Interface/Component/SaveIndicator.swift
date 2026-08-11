//
//  SaveIndicator.swift
//  SharedDesignSystemInterface
//
//  Created by 서정원 on 26/07/24.
//

import SwiftUI

/// 자동 저장 상태 표시 — Figma «tag-with-icon»(node 439:10567) 1:1.
/// 저장 중=회색 스피너 + «저장 중 ...», 저장됨=그린 체크 + «저장됨».
/// 텍스트는 gray/500 SemiBold14(.body5), 아이콘–텍스트 간격 8. 미저장(표시 없음)은 호출부가 뷰 자체를 숨긴다.
///
/// 스피너는 시스템 `ProgressView` 가 아니라 DS 에셋(`Image.Loading.ingGray16`)을 회전시킨다 —
/// 시안이 지정한 도형·색이고, 원본색 에셋이라 틴트가 통하지 않는다(사고 사례 1번).
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
        HStack(spacing: .ds(.p8)) {
            switch status {
            case .saving:
                Spinner()
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
            .dsTypography(.body5)
            .foregroundStyle(Color.GrayScale.g500)
    }

    /// 시안의 `loading/ing/16px/gray` 에셋을 무한 회전시켜 스피너로 쓴다.
    /// 별도 뷰로 뺀 이유 — `@State` 를 이 자리에 묶어 두면 상태가 `.saved` 로 바뀔 때
    /// 통째로 사라지고, 다시 `.saving` 이 되면 `onAppear` 가 새로 돌아 애니메이션이 되살아난다.
    private struct Spinner: View {
        @State private var isSpinning = false

        var body: some View {
            Image.Loading.ingGray16
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
                .onAppear { isSpinning = true }
        }
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
