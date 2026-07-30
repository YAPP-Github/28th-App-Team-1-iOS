//
//  VideoCountdownCard.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 면접 영상 진입 카드 — Figma «countdown-card»(property1=active / end).
/// 남은 시청 시간을 1초마다 갱신한다.
///
/// 갱신을 `TimelineView` 로 뷰 안에서 처리하는 이유: 남은 시간은 서버 `expiresAt` 에서 파생되는 표시값이라
/// State 에 둘 필요가 없다. 리듀서에 1초 틱 effect 를 넣으면 폴링과 무관한 액션이 매초 흘러
/// 테스트·디버깅만 시끄러워진다.
struct VideoCountdownCard: View {
    /// 시청 만료 시각 — nil 이면 서버가 기한을 안 내린 것이라 카운트다운을 감춘다.
    let expiresAt: Date?
    /// 재생 불가(만료·주소 없음) — 회색 변형으로 낮추고 탭을 막는다.
    let isExpired: Bool
    let onTap: () -> Void

    var body: some View {
        // 셀 것이 남았을 때만 매초 다시 그린다 — 만료됐거나 기한을 모르면 정적으로 한 번만 그린다.
        if let expiresAt, !isExpired {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = max(0, expiresAt.timeIntervalSince(context.date))
                button(remaining: remaining, isEnded: remaining == 0)
            }
        } else {
            button(remaining: isExpired ? 0 : nil, isEnded: isExpired)
        }
    }

    private func button(remaining: TimeInterval?, isEnded: Bool) -> some View {
        Button(action: onTap) {
            card(remaining: remaining, isEnded: isEnded)
        }
        .buttonStyle(.plain)
        .disabled(isExpired)
    }

    private func card(remaining: TimeInterval?, isEnded: Bool) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p10)) {
            HStack(spacing: 0) {
                Text(Self.title)
                    .dsTypography(isEnded ? .sub7 : .body2)
                    .foregroundStyle(isEnded ? Color.GrayScale.g300 : Color.BlackWhite.white)
                Spacer(minLength: .ds(.p8))
                (isEnded ? Image.Right.disabled16 : Image.Right.white16)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }

            Rectangle()
                .fill(Color.GrayScale.g800)
                .frame(height: .ds(.small))

            HStack(spacing: 0) {
                HStack(spacing: .ds(.p8)) {
                    (isEnded ? Image.Timer.disabled24 : Image.Timer.green24)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(isEnded ? Self.expiredMessage : Self.activeMessage)
                        .dsTypography(.body9)
                        // @ds(color): #D2D6DE (Figma Gray scale/300) → GrayScale.g200 — 다크 카드 보조 텍스트, 팔레트에 s계열 없음
                        .foregroundStyle(Color.GrayScale.g200)
                        .opacity(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: .ds(.p8))
                if let remaining {
                    Text(Self.formatted(remaining))
                        .dsTypography(.sub3)
                        .foregroundStyle(isEnded ? Color.GrayScale.g300 : Color.BlackWhite.white)
                        .monospacedDigit()
                }
            }
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.HilitBlack.b800)
    }

    /// HH:MM:SS — 하루를 넘겨도 시(hour) 자리로 이어 붙인다(00:00:00 자리수 고정).
    static func formatted(_ remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.down))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    static let title = "면접 영상 다시보기"
    static let activeMessage = "이 시간이 지나면\n면접 영상을 볼 수 없어요."
    static let expiredMessage = "면접 영상의 시청 기간이 만료되었어요."
}

#Preview("영상 카드") {
    VStack(spacing: .ds(.p16)) {
        VideoCountdownCard(
            expiresAt: Date().addingTimeInterval(3725),
            isExpired: false,
            onTap: {}
        )
        VideoCountdownCard(expiresAt: nil, isExpired: true, onTap: {})
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
