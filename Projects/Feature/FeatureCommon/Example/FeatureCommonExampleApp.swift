//
//  FeatureCommonExampleApp.swift
//  FeatureCommonExample
//
//  Created by EunseoKim on 26/07/10.
//

import ComposableArchitecture
import CoreNetworkInterface
import FeatureCommonImplementation
import SwiftUI

@main
struct FeatureCommonExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NetworkExampleView(
                store: Store(initialState: NetworkExampleFeature.State()) {
                    NetworkExampleFeature()
                } withDependencies: {
                    // Example 도 composition root — umbrella link 로 JobClient.liveValue 가 그대로 돈다 (D4).
                    // 최하단 transport(NetworkClient)와 토큰만 스텁으로 교체:
                    // Domain liveValue 와 AuthorizedNetworkClient(Bearer 첨부)의 경로·디코딩 코드는 실제로 실행된다.
                    let tokenStore = TokenStore.inMemory
                    tokenStore.save(AuthTokens(accessToken: "example-access", refreshToken: "example-refresh"))
                    $0.tokenStore = tokenStore
                    $0.networkClient = NetworkClient(request: { _ in
                        try await Task.sleep(for: .seconds(1))   // 로딩 상태 확인용
                        return Data("""
                        {"success": true, "data": {"jobs": [
                            {"jobId": 1, "jobRole": "BACKEND", "label": "백엔드"},
                            {"jobId": 2, "jobRole": "FRONTEND", "label": "프론트엔드"},
                            {"jobId": 3, "jobRole": "IOS", "label": "iOS"}
                        ]}}
                        """.utf8)
                    })
                }
            )
        }
    }
}
