//
//  DeeplinkClientLive.swift
//  DomainDeeplinkImplementation
//
//  Created by 서정원 on 26/08/13.
//

import ChottuLinkSDK
import ComposableArchitecture
import CoreCommonInterface
import DomainDeeplinkInterface
import Foundation

/// 델리게이트 콜백을 실어 나르는 통로. **전역**인 건 두 가지 때문이다 —
/// 스트림 소비(App)는 MainActor 밖이고, 브리지 인스턴스보다 오래 살아야 한다.
private let resolvedLinkStream = AsyncStream<URL>.makeStream()

extension DeeplinkClient: @retroactive DependencyKey {
    public static var liveValue: DeeplinkClient {
        DeeplinkClient(
            start: { apiKey in ChottuLinkBridge.shared.start(apiKey: apiKey) },
            // 결과를 안 받는다 — 진입은 호출부가 원본 URL 로 이미 처리했고, 여기 넘기는 목적은
            // 클릭 어트리뷰션(설치 상태)과 매칭 재료 적립뿐이다.
            handle: { url in
                DeeplinkLogger.handling(url)
                ChottuLink.handleLink(url)
            },
            resolvedLinks: { resolvedLinkStream.stream }
        )
    }
}

/// SDK 델리게이트를 AsyncStream 으로 잇는 브리지. 싱글턴인 건 SDK 가 델리게이트를 오래 붙잡아 준다는
/// 보장이 없어서다 — 지역 인스턴스로 두면 초기화 직후 사라져 deferred 콜백이 아무 데도 도착하지 않는다.
@MainActor
private final class ChottuLinkBridge: ChottuLinkDelegate {
    static let shared = ChottuLinkBridge()

    private var hasStarted = false

    /// 재초기화는 SDK 계약에 없다 — 두 번째 호출은 무시한다(Example 하네스가 겹쳐 부를 수 있다).
    func start(apiKey: String) {
        guard !hasStarted else { return }
        hasStarted = true
        DeeplinkLogger.starting(hasKey: !apiKey.isEmpty)
        ChottuLink.initialize(
            config: CLConfiguration(apiKey: apiKey, isDebugEnabled: LogGate.isVerbose, delegate: self)
        )
    }

    // MARK: ChottuLinkDelegate

    func chottuLink(didInitializeWith configuration: CLConfiguration) {
        DeeplinkLogger.initialized()
    }

    func chottuLink(didFailToInitializeWith error: any Error) {
        // 초기화 실패는 곧 «deferred 없음» 이다 — 설치 상태 진입은 SDK 없이 도는 게 설계라 앱은 그대로 산다.
        DeeplinkLogger.failure("초기화", error)
    }

    func chottuLink(didResolveDeepLink link: URL, metadata: [String: Any]?) {
        let candidates = DeeplinkResolution.candidates(link: link, metadata: metadata)
        DeeplinkLogger.resolved(link: link, metadata: metadata, candidates: candidates)
        for url in candidates {
            resolvedLinkStream.continuation.yield(url)
        }
    }

    func chottuLink(didFailToResolveDeepLink originalURL: URL?, error: any Error) {
        // 여기서 할 수 있는 일이 없다 — 설치 상태 진입은 원본 URL 이 이미 처리했고,
        // deferred 는 재료 자체가 없다. 삼키고(로그만 남기고) 링크 재탭을 기다린다.
        DeeplinkLogger.failure("해석 \(originalURL?.absoluteString ?? "(원본 없음)")", error)
    }
}

/// 링크 수신 로깅. **deferred 는 눈으로 볼 화면 변화가 없다** — 재설치 후 첫 실행에서 아무 일도 안 일어나면
/// 콜백이 안 온 것인지, 왔는데 토큰이 없던 것인지, 파서가 버린 것인지 구분할 길이 이 로그뿐이다.
/// 노출 여부는 `LogGate.isVerbose`(Dev·QA, 또는 디버거가 붙은 Prod).
enum DeeplinkLogger {
    static func starting(hasKey: Bool) {
        guard LogGate.isVerbose else { return }
        print("🔗 [DEEPLINK] SDK 시작 — apiKey \(hasKey ? "있음" : "없음(deferred 비활성)")")
    }

    static func initialized() {
        guard LogGate.isVerbose else { return }
        print("🔗 [DEEPLINK] SDK 초기화 완료")
    }

    static func handling(_ url: URL) {
        guard LogGate.isVerbose else { return }
        print("🔗 [DEEPLINK] SDK 로 전달(어트리뷰션) — \(url.absoluteString)")
    }

    /// 후보 선택의 **근거까지** 남긴다 — 어느 쪽에 토큰이 실려 오는지가 이 연동의 유일한 미지수라
    /// 실패했을 때 metadata 원문이 없으면 원인을 좁힐 수 없다.
    static func resolved(link: URL, metadata: [String: Any]?, candidates: [URL]) {
        guard LogGate.isVerbose else { return }
        print("🔗 [DEEPLINK] 해석됨 — link: \(link.absoluteString)")
        print("   metadata: \(metadata.map { "\($0)" } ?? "(없음)")")
        print("   후보: \(candidates.map(\.absoluteString))")
    }

    static func failure(_ step: String, _ error: any Error) {
        guard LogGate.isVerbose else { return }
        print("🚧 [DEEPLINK] \(step) 실패 — \(error)")
    }
}

/// 해석 결과에서 **토큰이 살아 있을 만한 URL** 을 뽑는다.
///
/// SDK 는 두 가지를 준다: `link`(대시보드에 등록한 destination — 고정값이라 토큰이 없을 수 있다)와
/// 메타데이터의 `shortLinkRaw`(«파라미터가 그대로인 딥링크»). 어느 쪽에 토큰이 실려 오는지 계약이
/// 못 박지 않았으므로 **둘 다 흘리고** 판정은 파서에 맡긴다 — 한쪽만 골랐다가 틀리면 진입이 통째로 죽는다.
/// 순서는 raw 우선(파라미터가 온전한 쪽), 중복이면 하나만.
// @lat: [[deeplink#해석 후보]]
enum DeeplinkResolution {
    static func candidates(link: URL, metadata: [String: Any]?) -> [URL] {
        guard let raw = rawShortLink(metadata), raw != link else { return [link] }
        return [raw, link]
    }

    /// `shortLinkRaw` 의 표현이 URL 인지 String 인지 계약에 없다 — 둘 다 받는다.
    private static func rawShortLink(_ metadata: [String: Any]?) -> URL? {
        switch metadata?["shortLinkRaw"] {
        case let raw as URL: raw
        case let raw as String: URL(string: raw)
        default: nil
        }
    }
}
