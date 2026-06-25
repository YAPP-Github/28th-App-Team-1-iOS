import ProjectDescription

/// 모듈 간 의존을 타입드 액세서로 노출해 각 `Project.swift` 의 보일러플레이트를 제거한다.
///
/// 경로는 모두 루트(`Workspace.swift` 가 있는 위치) 기준 `.relativeToRoot`.
public extension TargetDependency {
    // MARK: External

    static let composableArchitecture: TargetDependency = .external(name: "ComposableArchitecture")

    // MARK: Core / Shared

    static let models: TargetDependency = .project(
        target: "Models",
        path: .relativeToRoot("Projects/Shared/Models")
    )

    static let designSystemKit: TargetDependency = .project(
        target: "DesignSystemKit",
        path: .relativeToRoot("Projects/Shared/DesignSystemKit")
    )

    /// 순정 URLSession HTTP transport. `*ClientLive` 만 의존한다 (Interface·Feature 는 X).
    static let networking: TargetDependency = .project(
        target: "Networking",
        path: .relativeToRoot("Projects/Shared/Networking")
    )

    /// 실행 환경(개발계/운영계) 설정. App·`*ClientLive` 만 의존한다 (Feature 는 X).
    static let appConfig: TargetDependency = .project(
        target: "AppConfig",
        path: .relativeToRoot("Projects/Shared/AppConfig")
    )

    // MARK: Client (Interface / Live)

    /// 예: `.clientInterface("User")` → `UserClientInterface`
    static func clientInterface(_ name: String) -> TargetDependency {
        .project(
            target: "\(name)ClientInterface",
            path: .relativeToRoot("Projects/Client/\(name)Client")
        )
    }

    /// 예: `.clientLive("User")` → `UserClientLive` (App 타겟 / Example 앱만 link)
    static func clientLive(_ name: String) -> TargetDependency {
        .project(
            target: "\(name)ClientLive",
            path: .relativeToRoot("Projects/Client/\(name)Client")
        )
    }

    // MARK: Feature

    /// 예: `.feature("Users")` → `UsersFeature`
    static func feature(_ name: String) -> TargetDependency {
        .project(
            target: "\(name)Feature",
            path: .relativeToRoot("Projects/Feature/\(name)")
        )
    }
}
