//
//  PeerFeedbackCard.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

// Figma: «feedback request-card» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-1433

import SharedDesignSystemInterface
import SwiftUI

/// 지인 피드백 요청 카드 — Figma «feedback request-card» 435:1433.
/// 왼쪽 그린 바 + 제목 · 참여 수 · 안내 · 진입 화살표.
///
/// DS 에 대응 컴포넌트가 없다(`FeedbackCard` 는 흰 판의 «피드백 한 장» 으로 다른 것이다) —
/// 두 번째 사용처가 생기면 승격 후보다.
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
                    // @ds(spacing): 6 — 제목·구분바·참여수 사이 (spacing 스케일이 4 다음 8)
                    HStack(spacing: 6) {
                        Text(Self.title)
                            .dsTypography(.body2)
                            .foregroundStyle(Color.BlackWhite.white)
                        Rectangle()
                            .fill(Color.GrayScale.g700)
                            .frame(width: .ds(.small), height: Metric.separatorHeight)
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

                // 시안은 `right/16px/grey` — 흰 쉐브론이 아니다(g900 판 위에서 한 단계 낮춘 회색).
                Image.Right.gray16
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.chevronSide, height: Metric.chevronSide)
            }
            .padding(.trailing, .ds(.p16))
            // 시안 카드 높이는 왼쪽 그린 바(70)가 정한다 — 글자가 두 줄뿐이라 그냥 두면 카드가 얕아진다.
            .frame(maxWidth: .infinity, minHeight: Metric.minHeight, alignment: .leading)
            .background(Color.GrayScale.g900)
        }
        .buttonStyle(.plain)
    }

    private enum Metric {
        /// 쉐브론 한 변 16 — Figma `right/16px`.
        static let chevronSide: CGFloat = 16
        // @ds(layout): 70 — 카드 최소 높이(시안 왼쪽 그린 바 높이)
        static let minHeight: CGFloat = 70
        // @ds(layout): 16 — 제목·참여수 사이 세로 구분 바 높이
        static let separatorHeight: CGFloat = 16
    }

    static let title = "지인에게 면접 영상 보내기"
}

#Preview("지인 피드백 카드") {
    PeerFeedbackCard(participantCount: 0, maxCount: 4, onTap: {})
        .padding(.ds(.p20))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.HilitBlack.b900)
}
