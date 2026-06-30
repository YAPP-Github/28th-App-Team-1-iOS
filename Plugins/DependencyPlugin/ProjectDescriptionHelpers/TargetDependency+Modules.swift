import ProjectDescription

public extension TargetDependency {

    // MARK: External

    static let composableArchitecture: TargetDependency = .external(name: "ComposableArchitecture")

    // MARK: Layer Umbrellas
    //
    // Implementation까지 포함하므로 App(composition root)과 Example 앱에서만 사용한다.
    // Feature/Domain 서브모듈은 아래 Interface-only 액세서를 사용해야 한다.

    static var core: Self { .project(target: "Core", path: .coreLayer) }
    static var domain: Self { .project(target: "Domain", path: .domainLayer) }
    static var feature: Self { .project(target: "Feature", path: .featureLayer) }
    static var shared: Self { .project(target: "Shared", path: .sharedLayer) }

    // MARK: Interface-only
    //
    // 레이어 간 Dependency Inversion을 지키기 위한 Interface 전용 액세서.
    //   Feature Implementation → .domain(interface: .xxx)   (비즈니스 로직 추상화 사용)
    //   Domain  Implementation → .core(interface: .xxx)     (인프라 추상화 사용)
    // Interface만 링크하므로 구현체를 모른다 → 추상화 경계 유지.

    static func core(interface module: ModulePath.Core) -> Self {
        .project(
            target: "Core\(module.rawValue)Interface",
            path: .core(module)
        )
    }

    static func domain(interface module: ModulePath.Domain) -> Self {
        .project(
            target: "Domain\(module.rawValue)Interface",
            path: .domain(module)
        )
    }

    static func shared(interface module: ModulePath.Shared) -> Self {
        .project(
            target: "Shared\(module.rawValue)Interface",
            path: .shared(module)
        )
    }
}
