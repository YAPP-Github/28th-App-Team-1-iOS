//
//  HomeStartInterviewView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import SwiftUI

/// Figma «HomeStartInterview» — 시작 CTA 변형 스텁 (처음 / 등록 포폴 있음 / 무료 횟수 모두 사용).
/// 시안 수령 시 위젯① 상태별 UI 로 채운다 — 소진(exhausted)은 NO_REMAINING 안내(MVP 후 페이월 자리).
struct HomeStartInterviewView: View {
    let variant: HomeFeature.StartVariant

    var body: some View {
        VStack(spacing: 8) {
            Text("HomeStartInterview")
            Text(variantLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var variantLabel: String {
        switch variant {
        case .first: "처음 (포트폴리오 없음)"
        case .hasPortfolio: "등록된 포트폴리오 있음"
        case .exhausted: "무료 횟수 모두 사용"
        }
    }
}

#Preview("처음") {
    HomeStartInterviewView(variant: .first)
}

#Preview("소진") {
    HomeStartInterviewView(variant: .exhausted)
}
