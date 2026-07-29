//
//  PeerFeedbackCard.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 지인 피드백 요청 카드 — Figma «feedback request-card». 왼쪽 그린 바 + 제목 · 참여 수 · 안내 · 진입 화살표.
///
/// 분모(정원)는 서버가 안 내려서 `ReportMainFeature.maxGuestCount` 상수를 쓴다 —
/// 서버에 정원 필드가 생기면 그 값만 바꿔 끼우면 된다.
struct PeerFeedbackCard: View {
    /// 이미 제출한 지인 수.
    let participantCount: Int
    /// 요청 가능한 최대 인원.
    let maxCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: .ds(.p16)) {
                Rectangle()
                    .fill(Color.HilitGreen.g500)
                    .frame(width: .ds(.large))
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: .ds(.p4)) {
                    HStack(spacing: 6) {
                        Text(Self.title)
                            .dsTypography(.body2)
                            .foregroundStyle(Color.BlackWhite.white)
                        Rectangle()
                            .fill(Color.GrayScale.g700)
                            .frame(width: .ds(.small), height: 16)
                        Text("\(participantCount)/\(maxCount)")
                            .dsTypography(.body2)
                            .foregroundStyle(Color.BlackWhite.white)
                    }
                    Text("\(maxCount)명에게 영상을 공유하고 태도 분석을 받아보세요!")
                        .dsTypography(.body7)
                        // @ds(color): #D2D6DE (Figma Gray scale/300) → GrayScale.g200 — 다크 카드 보조 텍스트, 팔레트에 s계열 없음
                        .foregroundStyle(Color.GrayScale.g200)
                        .opacity(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image.Right.white16
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .padding(.trailing, .ds(.p16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.GrayScale.g900)
        }
        .buttonStyle(.plain)
    }

    static let title = "지인에게 면접 영상 보내기"
}

#Preview("지인 피드백 카드") {
    PeerFeedbackCard(participantCount: 0, maxCount: 4, onTap: {})
        .padding(.ds(.p20))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.HilitBlack.b900)
}
