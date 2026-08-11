//
//  AppVersionClientLive.swift
//  DomainAppVersionImplementation
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainAppVersionInterface
import DomainCommonInterface
import Foundation

// @lat: [[api#AppVersion]]
// depends-on: [[domain.map#네트워킹 인프라]]
// 무인증 API — Bearer 를 붙이는 AuthorizedNetworkClient 가 아니라 NetworkClient 를 직접 쓴다.
extension AppVersionClient: @retroactive DependencyKey {
    public static var liveValue: AppVersionClient {
        @Dependency(\.networkClient) var network

        return AppVersionClient(
            check: { version in
                try await AppVersionError.mapping {
                    let request = NetworkRequest(
                        path: "/api/v1/app-versions/check",
                        queryItems: [
                            URLQueryItem(name: "platform", value: "IOS"),
                            URLQueryItem(name: "version", value: version)
                        ]
                    )
                    return try await network.api(request)
                }
            }
        )
    }
}
