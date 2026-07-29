//
//  FieldSubText.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/30.
//

// Figma: «text-sub» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2044-1658

import SwiftUI

/// 입력 필드 아래 붙는 서브 텍스트 한 줄 — Figma «text-sub» 2044:1658 (`status` 축 3종).
///
/// 아이콘 16 + 14pt 한 줄(넘치면 말줄임). `InfoField`(판 있는 안내 박스)와 달리 판이 없는 맨 줄이다.
/// 아이콘·색은 파라미터가 아니라 status 에 묶어 닫았다 — 열어두면 시안에 없는 조합이 만들어진다:
/// `.info` info/disabled + g300 · `.success` success/green + g800 · `.error` issue/error + e500.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
/// 필드와 함께 쓸 땐 `HilitTextField` 가 내장하고 있어 직접 조립할 일이 드물다.
public struct FieldSubText: View {
    /// Figma `status` 축. `default` 는 회색 안내(info 아이콘)라 `.info` 로 옮겼다.
    public enum Status: Sendable, CaseIterable {
        /// 회색 안내 (Figma `default` — 아이콘 info/16px/disabled)
        case info
        /// 초록 성공 (Figma `success` — 아이콘 success/16px/green)
        case success
        /// 빨간 에러 (Figma `error` — 아이콘 issue/16px/error)
        case error
    }

    private let text: String
    private let status: Status

    /// - Parameters:
    ///   - text: 서브 문구. 한 줄로 잘리고 넘치면 말줄임.
    ///   - status: Figma `status` 축.
    public init(_ text: String, status: Status = .info) {
        self.text = text
        self.status = status
    }

    public var body: some View {
        HStack(spacing: Metric.gap) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: Metric.iconSide, height: Metric.iconSide)
            Text(text)
                .dsTypography(.body6)
                .foregroundStyle(foreground)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var icon: Image {
        switch status {
        case .info: Image.Info.disabled
        case .success: Image.Success.green16
        case .error: Image.Issue.error16
        }
    }

    private var foreground: Color {
        switch status {
        case .info: Color.GrayScale.g300
        case .success: Color.HilitGreen.g800
        case .error: Color.Error.e500
        }
    }

    private enum Metric {
        /// 아이콘–글자 간격. Figma raw 6 — spacing 스케일에 없고 변수 바인딩도 없어 토큰화 보류.
        static let gap: CGFloat = 6
        /// 아이콘 한 변 16 — Figma 16px 변형뿐이라 파라미터로 열지 않는다.
        static let iconSide: CGFloat = 16
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .ds(.p12)) {
        FieldSubText("서브 텍스트를 입력해주세요")
        FieldSubText("서브 텍스트를 입력해주세요", status: .success)
        FieldSubText("서브 텍스트를 입력해주세요", status: .error)
        FieldSubText("아주 긴 서브 텍스트라서 한 줄에 들어가지 않고 말줄임으로 잘려야 하는 경우를 확인한다", status: .error)
    }
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
