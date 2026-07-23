//
//  GuestGateView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import SharedDesignSystemInterface
import SwiftUI

/// 차단·만료·기제출·완료 안내 — 문구는 PRD Part 4 확정 문구.
/// 전용 완료 프레임이 Figma «여기가 최종» 섹션에 없어 앱 표준 라이트 톤으로 구성한다
/// (라이트 배경 · 완료/기제출은 brand 체크, 그 외 차단은 중립 아이콘).
struct GuestGateView: View {
    enum Kind {
        case completed
        case closed(GuestFeedbackFeature.GateReason)
    }

    let kind: Kind

    var body: some View {
        VStack(spacing: .ds(.p20)) {
            // 히어로 아이콘 — 44pt 글리프에 대응하는 DS 토큰이 없어 시스템 사이즈를 유지한다.
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(iconColor)
            VStack(spacing: .ds(.p8)) {
                Text(title)
                    .dsTypography(.sub4)
                    .foregroundStyle(Color.dsTextPrimary)
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .dsTypography(.body6)
                        .foregroundStyle(Color.dsTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.ds(.p24))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dsBgLight)
    }

    private var icon: String {
        switch kind {
        case .completed: "checkmark.circle.fill"
        case .closed(.alreadySubmitted): "checkmark.circle"
        case .closed(.expired): "clock.badge.xmark"
        case .closed: "lock"
        }
    }

    /// 완료·기제출(감사 톤)은 brand 그린, 실제 차단은 중립 회색.
    private var iconColor: Color {
        switch kind {
        case .completed, .closed(.alreadySubmitted): .dsBrand
        case .closed: .dsTextTertiary
        }
    }

    private var title: String {
        switch kind {
        case .completed: "소중한 피드백 고마워요"
        case .closed(.private): "지금은 볼 수 없는 영상이에요"
        case .closed(.expired): "보관 기간이 지나 영상이 삭제되었어요"
        case .closed(.alreadySubmitted): "이미 제출하셨어요"
        case .closed(.invalidToken): "유효하지 않은 링크예요"
        case .closed(.unknown): "지금은 참여할 수 없어요"
        }
    }

    private var message: String? {
        switch kind {
        case .completed: "제출한 피드백은 최종 레포트에 바로 반영돼요."
        case .closed(.alreadySubmitted): "소중한 피드백 고마워요."
        case .closed: nil
        }
    }
}

#Preview("완료") {
    GuestGateView(kind: .completed)
}

#Preview("차단 - 만료") {
    GuestGateView(kind: .closed(.expired))
}

#Preview("차단 - 기제출") {
    GuestGateView(kind: .closed(.alreadySubmitted))
}

#Preview("차단 - 비공개") {
    GuestGateView(kind: .closed(.private))
}
