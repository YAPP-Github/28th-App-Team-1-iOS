//
//  GuestFeedbackModelsTests.swift
//  DomainFeedbackTests
//
//  Created by 서정원 on 26/07/20.
//

import CoreNetworkInterface
import DomainFeedbackInterface
import Foundation
import Testing

struct GuestFeedbackModelsTests {
    @Test("엔트리 응답을 디코딩한다 — videoUrl null 과 질문 경계 포함")
    func decodesEntryResponse() throws {
        let json = Data("""
        {
            "gate": "OPEN",
            "requesterName": "재원",
            "axes": [{"code": "GAZE", "displayName": "시선"}],
            "videoUrl": null,
            "questionBoundaries": [{"turnLevel": 1, "startAt": 42.5, "questionText": "자기소개 부탁드려요"}],
            "submissionOpen": true
        }
        """.utf8)

        let entry = try JSONDecoder.api.decode(GuestFeedbackEntry.self, from: json)

        #expect(entry.gate == .open)
        #expect(entry.requesterName == "재원")
        #expect(entry.axes == [AttitudeAxis(code: "GAZE", displayName: "시선")])
        #expect(entry.videoURL == nil)
        #expect(entry.questionBoundaries == [QuestionBoundary(turnLevel: 1, startAt: 42.5, questionText: "자기소개 부탁드려요")])
        #expect(entry.submissionOpen == true)
    }

    @Test("presigned 영상 URL 문자열을 URL 로 디코딩한다")
    func decodesVideoURL() throws {
        let json = Data("""
        {"gate": "OPEN", "axes": [], "videoUrl": "https://cdn.example.com/v.mp4", "questionBoundaries": [], "submissionOpen": true}
        """.utf8)

        let entry = try JSONDecoder.api.decode(GuestFeedbackEntry.self, from: json)

        #expect(entry.videoURL == URL(string: "https://cdn.example.com/v.mp4"))
    }

    @Test("미지 게이트 값과 누락 필드는 기본값으로 방어한다")
    func defendsUnknownGateAndMissingFields() throws {
        let json = Data(#"{"gate": "MAINTENANCE"}"#.utf8)

        let entry = try JSONDecoder.api.decode(GuestFeedbackEntry.self, from: json)

        #expect(entry.gate == .unknown)
        #expect(entry.axes.isEmpty)
        #expect(entry.questionBoundaries.isEmpty)
        #expect(entry.submissionOpen == false)   // OPEN 이 아니면 기본 false
        #expect(entry.videoURL == nil)
        #expect(entry.requesterName == nil)
    }

    @Test("제출 영수증의 ISO8601 시각을 디코딩한다")
    func decodesReceipt() throws {
        let json = Data(#"{"submissionId": 7, "submittedAt": "2026-07-20T05:00:00Z"}"#.utf8)

        let receipt = try JSONDecoder.api.decode(GuestSubmissionReceipt.self, from: json)

        #expect(receipt.submissionID == 7)
        #expect(receipt.submittedAt == Date(timeIntervalSince1970: 1_784_523_600))
    }

    @Test("draft 는 JSON 라운드트립이 된다")
    func draftRoundTrips() throws {
        let draft = GuestFeedbackDraft(
            nickname: "민지",
            ratings: ["GAZE": RatingDraft(level: 2, comment: "가끔 피해요")],
            overallFeedback: "좋았어요",
            startedEvaluation: true
        )

        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(GuestFeedbackDraft.self, from: data)

        #expect(decoded == draft)
    }
}
