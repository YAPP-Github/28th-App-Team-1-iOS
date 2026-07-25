//
//  UserClientLive.swift
//  DomainUserImplementation
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainUserInterface
import Foundation

// @lat: [[api#User]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension UserClient: @retroactive DependencyKey {
    public static var liveValue: UserClient {
        @Dependency(\.authorizedNetworkClient) var network

        return UserClient(
            profile: {
                try await UserError.mapping {
                    try await network.api(NetworkRequest(path: "/api/v1/users/me/profile"))
                }
            },
            updateProfile: { update in
                try await UserError.mapping {
                    let request = try NetworkRequest.json(
                        method: .patch,
                        path: "/api/v1/users/me/profile",
                        body: update
                    )
                    try await network.api(request)
                }
            },
            registerName: { name in
                try await UserError.mapping {
                    let request = try NetworkRequest.json(
                        method: .patch,
                        path: "/api/v1/users/me/name",
                        body: NameBody(name: name)
                    )
                    try await network.api(request)
                }
            },
            checkName: { name in
                try await UserError.mapping {
                    let request = NetworkRequest(
                        path: "/api/v1/users/name/check",
                        queryItems: [URLQueryItem(name: "name", value: name)]
                    )
                    let payload: NameCheckPayload = try await network.api(request)
                    return payload.available
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

private struct NameBody: Encodable {
    let name: String
}

private struct NameCheckPayload: Decodable, Sendable {
    let available: Bool
}
