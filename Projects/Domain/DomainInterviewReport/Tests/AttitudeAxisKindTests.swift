//
//  AttitudeAxisKindTests.swift
//  DomainInterviewReportTests
//
//  Created by EunSeo on 26/07/29.
//

import DomainInterviewReportInterface
import DomainInterviewReportTesting
import Testing

/// 태도 항목 코드 정규화 — 서버가 축을 늘려도 화면이 엉뚱한 항목으로 오인하지 않는지 고정한다.
struct AttitudeAxisKindTests {

    @Test("모르는 축 코드는 흡수한다")
    func unknownAxisIsAbsorbed() {
        #expect(AttitudeAxisKind(rawCode: "gaze") == .gaze)
        #expect(AttitudeAxisKind(rawCode: "NEW_AXIS") == nil)
        #expect(GuestAttitudeRating(axis: "VOICE", level: 1, comment: nil).axisKind == .voice)
    }

    @Test("평가는 서버 순서가 아니라 정해진 축 순서로 정렬되고 모르는 축은 빠진다")
    func ratingsFollowFixedAxisOrder() {
        let review = GuestReview(
            alias: "테스터",
            attitudeRatings: [
                GuestAttitudeRating(axis: "VOICE", level: 1, comment: nil),
                GuestAttitudeRating(axis: "NEW_AXIS", level: 1, comment: nil),
                GuestAttitudeRating(axis: "GAZE", level: 2, comment: nil)
            ]
        )

        #expect(review.orderedRatings.map(\.axis) == ["GAZE", "VOICE"])
    }

    @Test("같은 축이 중복으로 오면 첫 값만 쓴다")
    func duplicateAxisKeepsFirst() {
        let review = GuestReview(
            alias: nil,
            attitudeRatings: [
                GuestAttitudeRating(axis: "GAZE", level: 1, comment: nil),
                GuestAttitudeRating(axis: "GAZE", level: 4, comment: nil)
            ]
        )

        #expect(review.orderedRatings.count == 1)
        #expect(review.orderedRatings.first?.level == 1)
    }

    @Test("픽스처의 지인은 모르는 축을 빼고 5축 순서를 지킨다")
    func fixtureGuestsAreNormalized() {
        #expect(InterviewReportFixtures.firstGuest.orderedRatings.map(\.axis)
            == ["GAZE", "EXPRESSION", "POSTURE", "GESTURE", "VOICE"])
        #expect(InterviewReportFixtures.secondGuest.orderedRatings.map(\.axis) == ["GAZE"])
    }
}
