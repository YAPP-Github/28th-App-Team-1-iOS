//
//  DeeplinkClientMock.swift
//  DomainDeeplinkTesting
//
//  Created by 서정원 on 26/08/13.
//

import ComposableArchitecture
import DomainDeeplinkInterface
import Foundation

extension DeeplinkClient {
    /// 링크가 오지 않는 계 — 딥링크를 재현하지 않는 화면 테스트·Example 하네스가 쓴다.
    public static let mock = DeeplinkClient(
        start: { _ in },
        handle: { _ in },
        resolvedLinks: { AsyncStream { $0.finish() } }
    )

    /// 주어진 링크가 곧장 도착하는 계 — deferred 진입(설치 후 첫 실행)을 흉내 낸다.
    public static func mock(resolving urls: [URL]) -> DeeplinkClient {
        DeeplinkClient(
            start: { _ in },
            handle: { _ in },
            resolvedLinks: {
                AsyncStream { continuation in
                    urls.forEach { continuation.yield($0) }
                    continuation.finish()
                }
            }
        )
    }
}
