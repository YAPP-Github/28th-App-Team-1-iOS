//
//  AttitudeAxisKind.swift
//  DomainInterviewReportInterface
//
//  Created by EunSeo on 26/07/29.
//

import Foundation

/// 서버 `GuestAttitudeRating.axis`(String) 를 화면이 쓸 수 있게 좁힌 타입.
/// 보고서 응답은 코드만 내려주고 표시 이름을 주지 않는다(게스트 제출측 `AttitudeAxis` 와 달리) —
/// 그래서 코드 → 이름·아이콘 매핑은 화면 몫이고, 여기서는 **모르는 코드를 흡수**하는 일만 한다.
/// `HighlightTone` 과 같은 역할: 서버가 축을 늘려도 화면이 엉뚱한 항목으로 오인하지 않게 한다.
public enum AttitudeAxisKind: String, CaseIterable, Equatable, Sendable {
    case gaze = "GAZE"
    case expression = "EXPRESSION"
    case posture = "POSTURE"
    case gesture = "GESTURE"
    case voice = "VOICE"

    public init?(rawCode: String) {
        self.init(rawValue: rawCode.uppercased())
    }
}

public extension GuestAttitudeRating {
    /// 타입으로 좁힌 축. 서버가 새 코드를 내리면 nil — 화면은 그 줄을 건너뛴다.
    var axisKind: AttitudeAxisKind? { AttitudeAxisKind(rawCode: axis) }
}

public extension GuestReview {
    /// 서버 배열 순서와 무관하게 **정해진 축 순서**(시선·표정·자세·손동작·목소리)로 보여준다.
    /// 지인마다 순서가 달라지면 지인을 바꿔가며 비교할 때 눈이 따라가지 못한다.
    /// 모르는 코드·중복은 버린다.
    var orderedRatings: [GuestAttitudeRating] {
        let byAxis = Dictionary(
            (attitudeRatings ?? []).compactMap { rating in
                rating.axisKind.map { ($0, rating) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        return AttitudeAxisKind.allCases.compactMap { byAxis[$0] }
    }
}
