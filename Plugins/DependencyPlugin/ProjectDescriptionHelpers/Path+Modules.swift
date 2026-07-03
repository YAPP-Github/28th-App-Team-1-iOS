import ProjectDescription

public extension ProjectDescription.Path {

    // MARK: Layer roots
    // umbrella 타겟 경로 — App/Example 전용

    static var coreLayer: Self { .relativeToRoot("Projects/Core") }
    static var domainLayer: Self { .relativeToRoot("Projects/Domain") }
    static var featureLayer: Self { .relativeToRoot("Projects/Feature") }
    static var sharedLayer: Self { .relativeToRoot("Projects/Shared") }

    // MARK: Submodule paths
    // {Layer}{Name} 디렉토리 경로 — Interface 타입드 의존에서 사용

    static func core(_ module: ModulePath.Core) -> Self {
        .relativeToRoot("Projects/\(ModulePath.Core.name)/\(ModulePath.Core.name)\(module.rawValue)")
    }

    static func domain(_ module: ModulePath.Domain) -> Self {
        .relativeToRoot("Projects/\(ModulePath.Domain.name)/\(ModulePath.Domain.name)\(module.rawValue)")
    }

    static func feature(_ module: ModulePath.Feature) -> Self {
        .relativeToRoot("Projects/\(ModulePath.Feature.name)/\(ModulePath.Feature.name)\(module.rawValue)")
    }

    static func shared(_ module: ModulePath.Shared) -> Self {
        .relativeToRoot("Projects/\(ModulePath.Shared.name)/\(ModulePath.Shared.name)\(module.rawValue)")
    }
}
