import ProjectDescription

// MARK: - TargetFactory

public struct TargetFactory {
    var name: String
    var destinations: Destinations
    var product: Product
    var bundleId: String?
    var deploymentTargets: DeploymentTargets?
    var infoPlist: InfoPlist?
    var sources: SourceFilesList?
    var resources: ResourceFileElements?
    var scripts: [TargetScript]
    var dependencies: [TargetDependency]
    var settings: Settings?

    public init(
        name: String = "",
        destinations: Destinations = Project.Environment.destinations,
        product: Product = .staticFramework,
        bundleId: String? = nil,
        deploymentTargets: DeploymentTargets? = Project.Environment.deploymentTarget,
        infoPlist: InfoPlist? = nil,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        scripts: [TargetScript] = [],
        dependencies: [TargetDependency] = [],
        settings: Settings? = nil
    ) {
        self.name = name
        self.destinations = destinations
        self.product = product
        self.bundleId = bundleId
        self.deploymentTargets = deploymentTargets
        self.infoPlist = infoPlist
        self.sources = sources
        self.resources = resources
        self.scripts = scripts
        self.dependencies = dependencies
        self.settings = settings
    }
}

// MARK: - Target

public extension Target {

    private static func make(factory: TargetFactory) -> Self {
        .target(
            name: factory.name,
            destinations: factory.destinations,
            product: factory.product,
            bundleId: factory.bundleId
                ?? "\(Project.Environment.bundlePrefix).\(factory.name.lowercased())",
            deploymentTargets: factory.deploymentTargets,
            infoPlist: factory.infoPlist,
            sources: factory.sources,
            resources: factory.resources,
            scripts: factory.scripts,
            dependencies: factory.dependencies,
            settings: factory.settings
        )
    }

    // MARK: App

    /// composition root(App/Example) 공통 링크 설정.
    ///
    /// liveValue 활성화 보장 — 정적 아카이브는 참조된 오브젝트 파일만 링크하는데,
    /// Domain 등의 Implementation 은 extension(DependencyKey conformance)뿐이라 참조가 없어
    /// 통째로 탈락한다(→ 런타임에 testValue 폴백). `-all_load` 로 전 아카이브를 강제 적재한다.
    /// → lat.md architecture.md D4
    private static let compositionRootSettings: Settings = .settings(
        base: ["OTHER_LDFLAGS": "$(inherited) -all_load"]
    )

    /// App 앱 타겟.
    static func app(factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = Project.Environment.appName
        f.product = .app
        f.bundleId = f.bundleId ?? Project.Environment.bundlePrefix
        f.infoPlist = f.infoPlist ?? .extendingDefault(with: ["UILaunchScreen": [:]])
        f.sources = f.sources ?? ["Sources/**"]
        f.settings = f.settings ?? compositionRootSettings
        return make(factory: f)
    }

    // MARK: Docs

    /// 프로젝트 전역 DocC 카탈로그(Architecture.docc) 전용 호스트 타겟. 실행 코드 없음.
    /// 카탈로그의 심볼 링크 해석을 위해 문서가 참조하는 모듈(레이어 umbrella)을 의존으로 받는다.
    static func docs(factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "ArchitectureDocs"
        f.product = .framework
        f.bundleId = "\(Project.Environment.bundlePrefix).docs"
        f.sources = f.sources ?? ["Documentation/Sources/**"]
        f.resources = f.resources ?? ["Documentation/Architecture.docc/**"]
        return make(factory: f)
    }

    // MARK: Layer Umbrellas
    //
    // 역할 파라미터 없이 레이어 함수를 호출하면 어그리게이터 타겟이 생성된다.
    // factory.dependencies 에 하위 서브모듈 Implementation 들을 넘긴다.

    static func core(factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Core"
        f.sources = f.sources ?? ["Sources/**"]
        return make(factory: f)
    }

    static func domain(factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Domain"
        f.sources = f.sources ?? ["Sources/**"]
        return make(factory: f)
    }

    static func feature(factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Feature"
        f.sources = f.sources ?? ["Sources/**"]
        return make(factory: f)
    }

    static func shared(factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Shared"
        f.sources = f.sources ?? ["Sources/**"]
        return make(factory: f)
    }

    // MARK: Feature
    //
    // D3: Feature 는 Interface 를 두지 않는다 — 단일 Implementation 모듈(+Testing/Tests/Example).
    // 근거: `@Reducer` + `some` 정적 합성이 구체 타입을 강제해 Interface 로 못 가림.
    // → DocC `FeatureInterface` / lat.md architecture.md D3. (Core/Domain/Shared 와 달리 interface 팩토리 없음)

    static func feature(implements name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Feature\(name)Implementation"
        f.sources = f.sources ?? ["Sources/**"]
        f.scripts = [.swiftLint]
        return make(factory: f)
    }

    static func feature(testing name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Feature\(name)Testing"
        f.sources = f.sources ?? ["Testing/**"]
        f.dependencies = [.target(name: "Feature\(name)Implementation")] + f.dependencies
        return make(factory: f)
    }

    static func feature(tests name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Feature\(name)Tests"
        f.product = .unitTests
        f.sources = f.sources ?? ["Tests/**"]
        f.dependencies = [
            .target(name: "Feature\(name)Implementation"),
            .target(name: "Feature\(name)Testing")
        ] + f.dependencies
        return make(factory: f)
    }

    static func feature(example name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Feature\(name)Example"
        f.product = .app
        f.infoPlist = f.infoPlist ?? .extendingDefault(with: ["UILaunchScreen": [:]])
        f.sources = f.sources ?? ["Example/**"]
        f.dependencies = [.target(name: "Feature\(name)Implementation")] + f.dependencies
        f.settings = f.settings ?? compositionRootSettings   // Domain Implementation(liveValue) link 시에도 활성화 보장 (D4)
        return make(factory: f)
    }

    // MARK: Core

    static func core(interface name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Core\(name)Interface"
        f.sources = f.sources ?? ["Interface/**"]
        f.scripts = [.swiftLint]
        return make(factory: f)
    }

    static func core(implements name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Core\(name)Implementation"
        f.sources = f.sources ?? ["Sources/**"]
        f.scripts = [.swiftLint]
        f.dependencies = [.target(name: "Core\(name)Interface")] + f.dependencies
        return make(factory: f)
    }

    static func core(testing name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Core\(name)Testing"
        f.sources = f.sources ?? ["Testing/**"]
        f.dependencies = [.target(name: "Core\(name)Interface")] + f.dependencies
        return make(factory: f)
    }

    static func core(tests name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Core\(name)Tests"
        f.product = .unitTests
        f.sources = f.sources ?? ["Tests/**"]
        f.dependencies = [
            .target(name: "Core\(name)Implementation"),
            .target(name: "Core\(name)Testing")
        ] + f.dependencies
        return make(factory: f)
    }

    // MARK: Domain

    static func domain(interface name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Domain\(name)Interface"
        f.sources = f.sources ?? ["Interface/**"]
        f.scripts = [.swiftLint]
        return make(factory: f)
    }

    static func domain(implements name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Domain\(name)Implementation"
        f.sources = f.sources ?? ["Sources/**"]
        f.scripts = [.swiftLint]
        f.dependencies = [.target(name: "Domain\(name)Interface")] + f.dependencies
        return make(factory: f)
    }

    static func domain(testing name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Domain\(name)Testing"
        f.sources = f.sources ?? ["Testing/**"]
        f.dependencies = [.target(name: "Domain\(name)Interface")] + f.dependencies
        return make(factory: f)
    }

    static func domain(tests name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Domain\(name)Tests"
        f.product = .unitTests
        f.sources = f.sources ?? ["Tests/**"]
        f.dependencies = [
            .target(name: "Domain\(name)Implementation"),
            .target(name: "Domain\(name)Testing")
        ] + f.dependencies
        return make(factory: f)
    }

    // MARK: Shared

    static func shared(interface name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Shared\(name)Interface"
        f.sources = f.sources ?? ["Interface/**"]
        f.scripts = [.swiftLint]
        return make(factory: f)
    }

    static func shared(implements name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Shared\(name)Implementation"
        f.sources = f.sources ?? ["Sources/**"]
        f.scripts = [.swiftLint]
        f.dependencies = [.target(name: "Shared\(name)Interface")] + f.dependencies
        return make(factory: f)
    }

    static func shared(testing name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Shared\(name)Testing"
        f.sources = f.sources ?? ["Testing/**"]
        f.dependencies = [.target(name: "Shared\(name)Interface")] + f.dependencies
        return make(factory: f)
    }

    static func shared(tests name: String, factory: TargetFactory = .init()) -> Self {
        var f = factory
        f.name = "Shared\(name)Tests"
        f.product = .unitTests
        f.sources = f.sources ?? ["Tests/**"]
        f.dependencies = [
            .target(name: "Shared\(name)Implementation"),
            .target(name: "Shared\(name)Testing")
        ] + f.dependencies
        return make(factory: f)
    }
}
