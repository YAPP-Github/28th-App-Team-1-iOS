//
//  PrimaryButton.swift
//  DesignSystemKit
//
//  Created by EunseoKim on 5/26/26.
//

import SwiftUI

/// 디자인 시스템 표준 버튼.
///
/// Feature 화면에서 같은 모양의 버튼은 모두 이 컴포넌트로 통일한다.
public struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.dsHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .dsM)
                .background(Color.dsPrimary)
                .clipShape(RoundedRectangle(cornerRadius: .dsS))
        }
    }
}

#Preview {
    VStack(spacing: .dsM) {
        PrimaryButton("Save") {}
        PrimaryButton("Continue") {}
    }
    .padding(.dsL)
}
