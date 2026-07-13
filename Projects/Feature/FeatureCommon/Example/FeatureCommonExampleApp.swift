//
//  FeatureCommonExampleApp.swift
//  FeatureCommonExample
//
//  Created by EunseoKim on 26/07/10.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
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
                    // Example 도 composition root — umbrella link 로 InterviewClient.liveValue 가 그대로 돈다 (D4).
                    // 실 서버가 아직 없어(백엔드 진행 중) 최하단 transport(NetworkClient)만 스텁으로 교체:
                    // Domain liveValue 의 경로·디코딩 코드는 실제로 실행된다.
                    $0.networkClient = NetworkClient(request: { _ in
                        try await Task.sleep(for: .seconds(1))   // 로딩 상태 확인용
                        let encoder = JSONEncoder()
                        encoder.dateEncodingStrategy = .iso8601   // InterviewClient 의 iso8601 디코딩과 짝
                        return try encoder.encode(Interview.previews)
                    })
                }
            )
        }
    }
}
