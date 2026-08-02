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

    /// 요청이 하나라도 비행 중이면 true — 전역 로딩 오버레이 표출 조건.
    public var isLoading: Bool { inFlightCount > 0 }

    private init() {}

    func begin() { inFlightCount += 1 }
    func end() { inFlightCount -= 1 }
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
