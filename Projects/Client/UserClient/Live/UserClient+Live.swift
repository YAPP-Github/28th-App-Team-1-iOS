//
//  UserClient+Live.swift
//  UserClientLive
//

import ComposableArchitecture
import Foundation
import Models
import UserClientInterface

/// 실제 실행 환경에서 사용하는 ``UserClient`` 구현.
///
/// 본 모듈을 App 타겟이 link 하기만 하면 `liveValue` 가 자동 활성화된다.
/// Feature 모듈들은 ``UserClientInterface`` 만 import 하면 충분.
extension UserClient: DependencyKey {
    public static let liveValue = UserClient(
        fetchUsers: {
            try await Task.sleep(for: .milliseconds(800))
            return User.samples
        },
        fetchUser: { id in
            try await Task.sleep(for: .milliseconds(500))
            guard let user = User.samples.first(where: { $0.id == id }) else {
                throw UserClientError.notFound
            }
            return User(id: user.id, name: user.name, email: user.email, bio: "Loaded bio for \(user.name).")
        }
    )
}
