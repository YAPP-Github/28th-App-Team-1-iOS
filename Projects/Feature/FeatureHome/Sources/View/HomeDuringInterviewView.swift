//
//  HomeDuringInterviewView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import SwiftUI

/// Figma «HomeDuringInterview» — 진행 중 면접·레포트 제작 시점 스텁.
/// 시안 수령 시 [이어서 진행](같은 session_id 복귀)·레포트 생성 대기 UI 로 채운다 — docs/work/home-account.md §3.
struct HomeDuringInterviewView: View {
    let variant: HomeFeature.DuringVariant

    var body: some View {
        VStack(spacing: 8) {
            Text("HomeDuringInterview")
            Text(variantLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var variantLabel: String {
        switch variant {
        case .inProgress: "진행 중인 면접 있음 — [이어서 진행]"
        case .reportGenerating: "레포트 제작 중"
        }
    }
}

#Preview("진행 중") {
    HomeDuringInterviewView(variant: .inProgress)
}

#Preview("레포트 제작 중") {
    HomeDuringInterviewView(variant: .reportGenerating)
}
