//
//  GuestFeedbackShareLinkTests.swift
//  DomainFeedbackShareTests
//
//  Created by 서정원 on 26/08/13.
//

import DomainFeedbackShareInterface
import Foundation
import Testing

/// 조립(리포트)과 해석(게스트)이 갈라지지 않는지 — 갈라지면 만든 링크를 앱이 못 열고,
/// 그 실패는 링크를 받은 지인 쪽에서만 드러나 개발 중엔 안 보인다.
@Suite("지인 피드백 공유 링크")
struct GuestFeedbackShareLinkTests {
    @Test("조립한 링크를 그대로 되읽는다")
    func roundTrip() {
        let url = GuestFeedbackShareLink.url(token: "abc-123")

        #expect(url.absoluteString == "https://hilit.chottu.link/report?reportId=abc-123")
        #expect(GuestFeedbackShareLink.token(from: url) == "abc-123")
    }

    @Test("이스케이프가 필요한 토큰도 왕복한다")
    func roundTripEscapedToken() {
        let token = "a+b/c=d"
        let url = GuestFeedbackShareLink.url(token: token)

        #expect(GuestFeedbackShareLink.token(from: url) == token)
    }

    @Test("끝의 슬래시는 형식 판정에서 뺀다")
    func toleratesTrailingSlash() {
        let url = URL(string: "https://hilit.chottu.link/report/?reportId=abc-123")!

        #expect(GuestFeedbackShareLink.token(from: url) == "abc-123")
    }

    @Test("다른 도메인·경로·스킴은 받지 않는다")
    func rejectsForeignLink() {
        #expect(GuestFeedbackShareLink.token(from: URL(string: "https://evil.example.com/report?reportId=a")!) == nil)
        #expect(GuestFeedbackShareLink.token(from: URL(string: "https://hilit.chottu.link/feedback?reportId=a")!) == nil)
        #expect(GuestFeedbackShareLink.token(from: URL(string: "http://hilit.chottu.link/report?reportId=a")!) == nil)
    }

    /// 쿼리 이름은 Android 와 맞춘 계약이라 다른 이름은 받지 않는다 — 관대하게 받으면
    /// 두 플랫폼이 어긋난 채로도 «iOS 에선 되는» 상태가 되어 어긋남이 안 드러난다.
    @Test("쿼리 이름이 다르면 받지 않는다")
    func rejectsForeignQueryName() {
        #expect(GuestFeedbackShareLink.token(from: URL(string: "https://hilit.chottu.link/report?token=a")!) == nil)
    }
}
