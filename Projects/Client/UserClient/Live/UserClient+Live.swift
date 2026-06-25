//
//  UserClient+Live.swift
//  UserClientLive
//

import AppConfig
import ComposableArchitecture
import Foundation
import Models
import UserClientInterface

/// 실제 실행 환경에서 사용하는 ``UserClient`` 구현.
///
/// 본 모듈을 App 타겟이 link 하기만 하면 `liveValue` 가 자동 활성화된다.
/// Feature 모듈들은 ``UserClientInterface`` 만 import 하면 충분.
///
/// 환경(개발계/운영계)은 `@Dependency(\.appConfig)` 로 주입받아 `baseURL` 을 고른다.
/// Interface·Feature 는 이 분기를 전혀 모른다.
extension UserClient: DependencyKey {
    public static var liveValue: UserClient {
        @Dependency(\.appConfig) var config

        return UserClient(
            fetchUsers: {
                // 백엔드 준비 시: @Dependency(\.apiClient) var api 주입 후
                //   try await api.decoded([User].self, baseURL: config.baseURL, .init(path: "users"))
                // (Networking 모듈 + UserClient/Project.swift liveDependencies 에 .networking 추가)
                try await Task.sleep(for: .milliseconds(800))
                return User.samples
            },
            fetchUser: { id in
                // 백엔드 준비 시:
                //   try await api.decoded(User.self, baseURL: config.baseURL, .init(path: "users/\(id)"))
                try await Task.sleep(for: .milliseconds(500))
                guard let user = User.samples.first(where: { $0.id == id }) else {
                    throw UserClientError.notFound
                }
                return User(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    bio: "[\(config.environment.rawValue)] \(config.baseURL.host() ?? "") · \(user.name)"
                )
            }
        )
    }
}
