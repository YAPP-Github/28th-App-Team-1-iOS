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
            withdraw: {
                try await UserError.mapping {
                    let request = NetworkRequest(method: .delete, path: "/api/v1/users/me")
                    try await network.api(request)
                }
            }
        )
    }
}
