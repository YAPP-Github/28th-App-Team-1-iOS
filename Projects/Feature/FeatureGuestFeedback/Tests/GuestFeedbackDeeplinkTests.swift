//
//  GuestFeedbackDeeplinkTests.swift
//  FeatureGuestFeedbackTests
//
//  Created by 서정원 on 26/08/07.
//

import Foundation
import Testing
@testable import FeatureGuestFeedbackImplementation

struct GuestFeedbackDeeplinkTests {
    @Test("hilit://feedback/{token} 에서 토큰을 추출한다")
    func parsesToken() {
        let url = URL(string: "hilit://feedback/abc-123")!
        #expect(GuestFeedbackDeeplink.parse(url) == "abc-123")
    }

    @Test("유니버설 링크의 reportId 쿼리에서 토큰을 추출한다")
    func parsesUniversalLink() {
        let url = URL(string: "https://hilit.chottu.link/report?reportId=abc-123")!
        #expect(GuestFeedbackDeeplink.parse(url) == "abc-123")
    }

    @Test("유니버설 링크에 다른 쿼리가 섞여도 토큰을 찾는다")
    func parsesUniversalLinkWithExtraQuery() {
        // ChottuLink 가 붙이는 추적 파라미터(utm_*)가 섞여 온다 — 토큰만 골라낸다.
        let url = URL(string: "https://hilit.chottu.link/report?utm_source=kakao&reportId=abc-123")!
        #expect(GuestFeedbackDeeplink.parse(url) == "abc-123")
    }

    @Test("링크 도메인·경로가 다르면 nil")
    func rejectsForeignLink() {
        #expect(GuestFeedbackDeeplink.parse(URL(string: "https://feedback/abc-123")!) == nil)
        #expect(GuestFeedbackDeeplink.parse(URL(string: "https://evil.example.com/report?reportId=abc")!) == nil)
        #expect(GuestFeedbackDeeplink.parse(URL(string: "https://hilit.chottu.link/feedback?reportId=abc")!) == nil)
    }

    @Test("쿼리 이름이 다르면 nil — Android 와 맞춘 이름만 받는다")
    func rejectsForeignQueryName() {
        #expect(GuestFeedbackDeeplink.parse(URL(string: "https://hilit.chottu.link/report?token=abc")!) == nil)
    }

    @Test("유니버설 링크에 토큰이 없으면 nil")
    func rejectsUniversalLinkWithoutToken() {
        #expect(GuestFeedbackDeeplink.parse(URL(string: "https://hilit.chottu.link/report")!) == nil)
        #expect(GuestFeedbackDeeplink.parse(URL(string: "https://hilit.chottu.link/report?reportId=")!) == nil)
    }

    @Test("host 가 feedback 이 아니면 nil")
    func rejectsForeignHost() {
        let url = URL(string: "hilit://interview/abc-123")!
        #expect(GuestFeedbackDeeplink.parse(url) == nil)
    }

    @Test("토큰이 없거나 여분 세그먼트가 붙으면 nil")
    func rejectsMalformedPath() {
        #expect(GuestFeedbackDeeplink.parse(URL(string: "hilit://feedback")!) == nil)
        #expect(GuestFeedbackDeeplink.parse(URL(string: "hilit://feedback/")!) == nil)
        #expect(GuestFeedbackDeeplink.parse(URL(string: "hilit://feedback/a/b")!) == nil)
    }
}
