//
//  DeeplinkClient.swift
//  DomainDeeplinkInterface
//
//  Created by 서정원 on 26/08/13.
//

import ComposableArchitecture
import Foundation

/// 유니버설 링크 수신 seam — 링크 SaaS(ChottuLink) SDK 를 감싼 껍질이다. SDK 타입은 Implementation 밖으로 새지 않는다.
///
/// **수신 전용**: 링크 생성 API 는 부르지 않는다. 대시보드에 등록해 둔 링크 하나에 토큰만 갈아끼우므로
/// 조립은 문자열뿐이고 그건 `GuestFeedbackShareLink`(DomainFeedbackShare) 몫이다.
///
/// 설치 상태의 진입은 이 Client 없이도 성립한다 — Associated Domains 만 잡히면 iOS 가 쿼리 원본째
/// `onOpenURL` 로 꽂아준다. 이 Client 가 유일하게 담당하는 건 **deferred**(앱이 없어 스토어를 다녀온 뒤
/// 첫 실행) 경로와 클릭 어트리뷰션이다 — SDK 가 막혀도 잃는 건 그 둘뿐이다.
// @lat: [[deeplink#두 경로]]
public struct DeeplinkClient: Sendable {
    /// 앱 시작 시 1회 — SDK 초기화. 이 호출 전에 도착한 링크는 해석되지 않는다.
    public var start: @MainActor @Sendable (_ apiKey: String) -> Void
    /// 열린 URL 을 SDK 에 넘긴다(클릭 어트리뷰션·deferred 매칭). **진입 판정은 호출부가 원본 URL 로 따로 한다** —
    /// SDK 왕복을 기다리면 서드파티 네트워크가 화면 진입의 선행조건이 된다.
    public var handle: @MainActor @Sendable (URL) -> Void
    /// SDK 가 해석해 낸 링크. **deferred 는 이 스트림으로만 도착한다**(원본 URL 이 없는 경로라서).
    /// 한 번의 해석이 URL 을 여럿 흘릴 수 있다 — 토큰이 어느 쪽에 실려 오는지 SDK 계약이 못 박지 않아
    /// 후보를 다 흘리고 판정은 파서에 맡긴다. 소비자는 하나(App)를 전제한다 — 여럿이 구독하면 값을 나눠 갖는다.
    public var resolvedLinks: @Sendable () -> AsyncStream<URL>

    public init(
        start: @escaping @MainActor @Sendable (_ apiKey: String) -> Void,
        handle: @escaping @MainActor @Sendable (URL) -> Void,
        resolvedLinks: @escaping @Sendable () -> AsyncStream<URL>
    ) {
        self.start = start
        self.handle = handle
        self.resolvedLinks = resolvedLinks
    }
}

extension DeeplinkClient: TestDependencyKey {
    public static var testValue: DeeplinkClient {
        DeeplinkClient(
            start: unimplemented("DeeplinkClient.start"),
            handle: unimplemented("DeeplinkClient.handle"),
            resolvedLinks: unimplemented(
                "DeeplinkClient.resolvedLinks", placeholder: AsyncStream { $0.finish() }
            )
        )
    }

    /// 링크가 오지 않는 계 — 프리뷰는 딥링크 진입을 재현하지 않는다.
    public static var previewValue: DeeplinkClient {
        DeeplinkClient(
            start: { _ in },
            handle: { _ in },
            resolvedLinks: { AsyncStream { $0.finish() } }
        )
    }
}

extension DependencyValues {
    public var deeplinkClient: DeeplinkClient {
        get { self[DeeplinkClient.self] }
        set { self[DeeplinkClient.self] = newValue }
    }
}
