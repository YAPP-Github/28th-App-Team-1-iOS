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

    @Test("hilit 스킴이 아니면 nil")
    func rejectsForeignScheme() {
        let url = URL(string: "https://feedback/abc-123")!
        #expect(GuestFeedbackDeeplink.parse(url) == nil)
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
