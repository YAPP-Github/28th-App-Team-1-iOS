//
//  DeeplinkResolutionTests.swift
//  DomainDeeplinkTests
//
//  Created by 서정원 on 26/08/13.
//

import Foundation
import Testing

@testable import DomainDeeplinkImplementation

/// 해석 결과에서 토큰이 실려 올 URL 을 고르는 규칙. 여기가 틀리면 deferred 진입이 통째로 죽는다 —
/// 재설치 경로엔 원본 URL 이 없어 이 스트림 말고 다른 재료가 없다.
@Suite("딥링크 해석 후보")
struct DeeplinkResolutionTests {
    private let destination = URL(string: "https://hilit.chottu.link/report")!
    private let raw = URL(string: "https://hilit.chottu.link/report?reportId=abc-123")!

    @Test("파라미터가 온전한 shortLinkRaw 를 먼저 흘린다")
    func rawFirst() {
        let candidates = DeeplinkResolution.candidates(
            link: destination, metadata: ["shortLinkRaw": raw.absoluteString]
        )

        #expect(candidates == [raw, destination])
    }

    @Test("shortLinkRaw 가 URL 로 와도 같게 읽는다")
    func rawAsURL() {
        let candidates = DeeplinkResolution.candidates(link: destination, metadata: ["shortLinkRaw": raw])

        #expect(candidates == [raw, destination])
    }

    @Test("shortLinkRaw 가 없으면 destination 하나만 흘린다")
    func missingRaw() {
        #expect(DeeplinkResolution.candidates(link: destination, metadata: nil) == [destination])
        #expect(DeeplinkResolution.candidates(link: destination, metadata: ["isDeferred": true]) == [destination])
    }

    @Test("둘이 같으면 한 번만 흘린다")
    func deduplicates() {
        let candidates = DeeplinkResolution.candidates(link: raw, metadata: ["shortLinkRaw": raw.absoluteString])

        #expect(candidates == [raw])
    }
}
