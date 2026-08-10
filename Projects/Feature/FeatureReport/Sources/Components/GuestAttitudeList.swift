//
//  GuestAttitudeList.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

/// 지인 피드백 패널 — 지인 이름 탭 + 고른 지인의 태도 평가.
/// 피드백이 한 건이라도 있을 때 «지인에게 보내기» 요청 카드 **위에** 얹힌다(카드를 대체하지 않는다 —
/// 정원이 차기 전까지 다음 지인에게 또 보낼 수 있어야 한다).
struct GuestFeedbackPanel: View {
    let guests: [GuestReview]
    let selectedIndex: Int
    let expandedAxes: Set<String>
    let onSelectGuest: (Int) -> Void
    let onToggleComment: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            // 지인 이름 탭 — DS mini 버튼(다크 판) 그대로: 선택 green, 미선택 gray.
            // 판(surface)은 화면 루트(`ReportMainView`)가 `.hilitSurface(.dark)` 로 선언한다.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .ds(.p8)) {
                    ForEach(Array(guests.enumerated()), id: \.offset) { index, guest in
                        // 서버가 별명을 안 주면 순번으로 부른다 — 탭이 빈 칩으로 남지 않게.
                        Button(guest.alias ?? "지인 \(index + 1)") {
                            onSelectGuest(index)
                        }
                        .buttonStyle(.mini(index == selectedIndex ? .green : .gray))
                    }
                }
            }

            if guests.indices.contains(selectedIndex) {
                GuestAttitudeList(
                    ratings: guests[selectedIndex].orderedRatings,
                    expandedAxes: expandedAxes,
                    onToggleComment: onToggleComment
                )
            }
        }
    }
}

/// 지인 한 명의 태도 평가 목록 — Figma «Report_Main_Default»(지인 피드백 있음, 3329:5040).
/// 축(시선·표정·자세·손동작·목소리)마다 아이콘 + 이름 → 4단계 판정 문구 → 남긴 코멘트 순서로 쌓고
/// 축 사이를 divider 로 나눈다.
struct GuestAttitudeList: View {
    let ratings: [GuestAttitudeRating]
    /// 코멘트를 펼쳐 둔 축 코드.
    let expandedAxes: Set<String>
    let onToggleComment: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            ForEach(Array(ratings.enumerated()), id: \.offset) { index, rating in
                if index > 0 {
                    HilitDivider()
                }
                row(rating)
            }
        }
    }

    @ViewBuilder
    private func row(_ rating: GuestAttitudeRating) -> some View {
        if let axis = rating.axisKind {
            VStack(alignment: .leading, spacing: .ds(.p12)) {
                HStack(spacing: .ds(.p4)) {
                    GuestAttitudeCopy.icon20(for: axis)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(GuestAttitudeCopy.name(for: axis))
                        .dsTypography(.body2)
                        .foregroundStyle(Color.BlackWhite.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if let verdict = GuestAttitudeCopy.verdict(axis: axis, level: rating.level) {
                        Text(verdict)
                            .dsTypography(.sub7)
                            .foregroundStyle(Color.BlackWhite.white)
                    }
                    // 코멘트는 선택 입력이라 없으면 판정 문구만 남는다.
                    if let comment = rating.comment, !comment.isEmpty {
                        commentRow(comment, axisCode: rating.axis)
                    }
                }
            }
        }
    }

    /// 한 줄에 들어가는 코멘트는 그대로, 넘치는 코멘트만 말줄임 + 펼치기 화살표를 붙인다.
    /// `ViewThatFits` 는 후보의 **이상 크기**로 판정하므로, `lineLimit(1)` 을 걸어도
    /// 첫 후보의 이상 폭은 «줄바꿈 없는 전체 길이» 다 — 그게 안 들어가야 두 번째 후보로 넘어간다.
    @ViewBuilder
    private func commentRow(_ comment: String, axisCode: String) -> some View {
        let isExpanded = expandedAxes.contains(axisCode)

        if isExpanded {
            expandableComment(comment, axisCode: axisCode, isExpanded: true)
        } else {
            ViewThatFits(in: .horizontal) {
                commentText(comment).lineLimit(1)
                expandableComment(comment, axisCode: axisCode, isExpanded: false)
            }
        }
    }

    private func expandableComment(_ comment: String, axisCode: String, isExpanded: Bool) -> some View {
        Button {
            onToggleComment(axisCode)
        } label: {
            HStack(alignment: .top, spacing: .ds(.p8)) {
                commentText(comment)
                    .lineLimit(isExpanded ? nil : 1)
                    .truncationMode(.tail)
                Image.Down.disabled
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .buttonStyle(.plain)
    }

    private func commentText(_ comment: String) -> some View {
        Text(comment)
            .dsTypography(.body7)
            .foregroundStyle(Color.GrayScale.g200)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 태도 평가의 화면 문구·아이콘. 보고서 응답은 축 코드와 1~4 단계만 주고 표시 문구를 안 준다.
///
/// 🔴 시선·목소리 문구는 게스트 제출 화면의 확정 문구(Figma «객관식 - 선택 후»)를 서술형으로 옮긴 것이고,
/// 표정은 1단계만 리포트 시안(443:7102)에 있어 그 칸만 확정이다. 나머지(표정 2~4단계·자세·손동작)는
/// 그쪽도 확정 대기라 잠정 문구를 쓴다. 확정되면 이 표만 갈아끼운다.
enum GuestAttitudeCopy {
    static func name(for axis: AttitudeAxisKind) -> String {
        switch axis {
        case .gaze: "시선"
        case .expression: "표정"
        case .posture: "자세"
        case .gesture: "손동작"
        case .voice: "목소리"
        }
    }

    /// 20pt 판 — 리포트 메인의 태도 평가 목록.
    /// 크기별로 다시 그려진 별도 에셋이라 `.frame` 으로 늘리지 않고 크기마다 골라 쓴다 (`design/image.md`).
    static func icon20(for axis: AttitudeAxisKind) -> Image {
        switch axis {
        case .gaze: Image.Feedback.eyes20
        case .expression: Image.Feedback.face20
        case .posture: Image.Feedback.body20
        case .gesture: Image.Feedback.hand20
        case .voice: Image.Feedback.voice20
        }
    }

    /// 28pt 판 — 지인 피드백 항목 선택 화면(Figma `feedback/28px/*`).
    static func icon28(for axis: AttitudeAxisKind) -> Image {
        switch axis {
        case .gaze: Image.Feedback.eyes28
        case .expression: Image.Feedback.face28
        case .posture: Image.Feedback.body28
        case .gesture: Image.Feedback.hand28
        case .voice: Image.Feedback.voice28
        }
    }

    /// 4단계 판정 문구 (1=좋음 … 4=아쉬움). 서버가 범위 밖 값을 주면 nil — 그 줄은 판정 없이 코멘트만 남는다.
    static func verdict(axis: AttitudeAxisKind, level: Int?) -> String? {
        guard let level, (1...4).contains(level) else { return nil }
        return verdicts(for: axis)[level - 1]
    }

    private static func verdicts(for axis: AttitudeAxisKind) -> [String] {
        switch axis {
        case .gaze: ["잘 맞춰요.", "꽤 맞춰요.", "가끔 피해요.", "자주 피해요."]
        // 1단계 «밝아요.» 만 시안(443:7102) 확정값이라 그 칸만 시안대로 두고 2~4단계는 잠정 문구를 잇는다.
        case .expression: ["밝아요.", "괜찮아요.", "조금 아쉬워요.", "많이 아쉬워요."]
        case .voice: ["적당해요.", "너무 커요.", "조금 작아요.", "너무 작아요."]
        // 자세·손동작 — 축별 문구가 확정되지 않아 공통 잠정 문구를 쓴다.
        default: ["좋아요.", "괜찮아요.", "조금 아쉬워요.", "많이 아쉬워요."]
        }
    }
}

#Preview("지인 태도 평가") {
    GuestAttitudeList(
        ratings: [
            GuestAttitudeRating(axis: "GAZE", level: 3, comment: "꼬리질문에서 눈빛이 흔들려서 자신감이 없어 보였어요."),
            GuestAttitudeRating(
                axis: "EXPRESSION",
                level: 1,
                comment: "꼬리질문에서 눈빛이 흔들려서 자신감이 없어 보였어요. 그래서 조금 아쉬웠습니다."
            ),
            GuestAttitudeRating(axis: "POSTURE", level: 1, comment: nil),
            GuestAttitudeRating(axis: "GESTURE", level: 1, comment: nil),
            GuestAttitudeRating(axis: "VOICE", level: 3, comment: "목소리가 조금 작게 들렸어요.")
        ],
        expandedAxes: [],
        onToggleComment: { _ in }
    )
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.HilitBlack.b900)
}
