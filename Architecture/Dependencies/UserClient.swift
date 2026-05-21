import ComposableArchitecture
import Foundation

/// 사용자 데이터의 외부 접근 통로 (Repository).
///
/// Reducer 는 직접 인스턴스를 만들지 않고 항상 다음과 같이 주입해 사용합니다.
///
/// ```swift
/// @Dependency(\.userClient) var userClient
/// let users = try await userClient.fetchUsers()
/// ```
///
/// 환경 교체는 `DependencyValues` 의 `userClient`
/// 슬롯을 갈아끼우는 것으로 끝납니다.
///
/// ```swift
/// Store(initialState: AppFeature.State()) {
///     AppFeature()
/// } withDependencies: {
///     $0.userClient = .previewValue   // 또는 .testValue
/// }
/// ```
///
/// 새 엔드포인트를 추가하려면 클로저 프로퍼티를 한 줄 추가하고
/// `liveValue` / `previewValue` / `testValue` 셋 모두에 구현을 채워 넣으세요.
struct UserClient: Sendable {
    /// 전체 사용자 목록을 가져옵니다.
    var fetchUsers: @Sendable () async throws -> [User]
    /// 단일 사용자를 id 로 조회합니다.
    var fetchUser: @Sendable (Int) async throws -> User
}

extension UserClient: DependencyKey {
    /// 실서비스 환경. 현재는 mock 데이터를 지연 후 반환합니다.
    static let liveValue = UserClient(
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

    /// SwiftUI Preview 전용. 네트워크 지연 없이 즉시 반환합니다.
    static let previewValue = UserClient(
        fetchUsers: { User.samples },
        fetchUser: { id in
            guard let user = User.samples.first(where: { $0.id == id }) else {
                throw UserClientError.notFound
            }
            return User(id: user.id, name: user.name, email: user.email, bio: "Preview bio for \(user.name).")
        }
    )

    /// 단위 테스트 전용. 명시하지 않은 endpoint 호출 시 `unimplemented` 가 실패를 보고합니다.
    static let testValue = UserClient(
        fetchUsers: unimplemented("UserClient.fetchUsers", placeholder: []),
        fetchUser: unimplemented("UserClient.fetchUser", placeholder: User(id: 0, name: "", email: ""))
    )
}

extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

enum UserClientError: Error, Equatable {
    case notFound
}

extension User {
    static let samples: [User] = [
        .init(id: 1, name: "Ada Lovelace", email: "ada@example.com"),
        .init(id: 2, name: "Alan Turing", email: "alan@example.com"),
        .init(id: 3, name: "Grace Hopper", email: "grace@example.com"),
        .init(id: 4, name: "Linus Torvalds", email: "linus@example.com")
    ]
}
