//
//  NetworkActivity.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/08/02.
//

import Foundation
import Observation

// @lat: [[domain.map#네트워킹 인프라]]
/// 앱 전역 API in-flight 카운터. `trackingActivity()` 데코레이터만 증감하고,
/// AppView 가 `isLoading` 을 관찰해 전역 로딩(LoadingModal)을 표출한다.
@MainActor @Observable
public final class NetworkActivity {
    public static let shared = NetworkActivity()

    public private(set) var inFlightCount = 0

    /// 전역 로딩 오버레이 표출 조건 — **켜기는 늦추고, 끄기는 살짝 유예**한다.
    /// `inFlightCount > 0` 을 그대로 쓰면 두 곳에서 어긋난다.
    /// - 빠른 응답: 모달이 떴다 곧 사라져 «반짝» 한다 → `showDelay` 안에 끝나면 아예 안 띄운다.
    /// - 순차 호출: A 종료와 B 시작 사이에 카운트가 0 을 스쳐 «깜빡» 한다 → `settleDelay` 로 잇는다.
    ///
    /// 두 지연 모두 체인 전체에서 한 번씩만 든다 — 켜기 예약은 hop 마다 다시 걸지 않고,
    /// 끄기 예약은 다음 `begin()` 이 취소한다. API·콘텐츠 도착 시점엔 영향 없다(오버레이 전용).
    public private(set) var isLoading = false

    /// 켜기 지연 — 이 안에 끝나는 요청은 로딩을 표시하지 않는다.
    private static let showDelay: Duration = .milliseconds(200)

    /// 끄기 유예 — 체인 hop 사이 틈만 덮을 최소치. 완료 후 이만큼 딤이 남는다.
    private static let settleDelay: Duration = .milliseconds(80)

    /// 켜기 예약 진행 중 — 체인 중간에 카운트가 0 을 스쳐도 리셋하지 않는다.
    /// 그래야 지연이 **체인 시작 기준**으로 재져, 짧은 요청 여러 개가 이어질 때도 제때 뜬다.
    private var isShowScheduled = false

    /// 대기 중인 끄기 예약. 이어지는 `begin()` 이 취소해 표출을 물려받는다.
    private var hideTask: Task<Void, Never>?

    private init() {}

    func begin() {
        hideTask?.cancel()
        hideTask = nil
        inFlightCount += 1
        guard !isLoading, !isShowScheduled else { return }
        isShowScheduled = true
        // 취소하지 않는다 — 항상 완주해 예약 플래그를 내리고, 그 시점 카운트로 표출을 판정한다.
        Task { [weak self] in
            try? await Task.sleep(for: Self.showDelay)
            guard let self else { return }
            isShowScheduled = false
            guard inFlightCount > 0 else { return }   // 지연 안에 끝났다 — 표시 없이 넘어간다
            isLoading = true
        }
    }

    func end() {
        inFlightCount -= 1
        guard inFlightCount == 0, isLoading else { return }
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled, let self, inFlightCount == 0 else { return }
            isLoading = false
        }
    }
}

public extension NetworkClient {
    /// 요청 시작/종료를 `NetworkActivity.shared` 에 반영하는 데코레이터.
    /// liveValue 한 곳에만 씌운다 — Authorized·토큰 재발급 포함 모든 실 HTTP 가
    /// base client 를 지나므로 이 한 겹으로 전 API 가 잡힌다. (스텁 기반 테스트는
    /// `live(session:baseURL:)` 를 직접 쓰므로 계측에 안 걸린다.)
    func trackingActivity() -> NetworkClient {
        NetworkClient { request in
            await NetworkActivity.shared.begin()
            do {
                let data = try await self.request(request)
                await NetworkActivity.shared.end()
                return data
            } catch {
                // 취소(CancellationError) 포함 — actor hop 은 취소된 태스크에서도 완주한다
                await NetworkActivity.shared.end()
                throw error
            }
        }
    }
}
