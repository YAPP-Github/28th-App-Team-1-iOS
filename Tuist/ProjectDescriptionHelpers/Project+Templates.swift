import ProjectDescription

// MARK: - 빌드 구성 (3단계: Dev / QA / Release)
//
// Tuist 는 워크스페이스 내 모든 프로젝트가 **동일한 Configuration 집합**을 가질 때만
// generate 가 통과한다. 따라서 App 을 포함한 전 모듈이 아래 이름/타입을 공유한다.
//   • Dev     : 개발계 서버 + 디버그 메뉴. `DEV` 컴파일 조건이 켜져 `#if DEV` 코드가 포함된다.
//   • QA      : 개발계 서버, 디버그 메뉴 없음(테스터 배포용). `DEV` 미설정.
//   • Release : 운영계 서버.
// App 타겟만 여기에 더해 xcconfig(APP_ENV/API_BASE_URL/번들ID)를 얹는다 → `App/Project.swift`.
public extension Settings {
    static var standard: Settings {
        .settings(configurations: [
            .debug(name: "Dev", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEV"]),
            .debug(name: "QA"),
            .release(name: "Release")
        ])
    }
}

// MARK: - 공통 상수

private let bundlePrefix = "com.yapp01.architecture"
private let appDestinations: Destinations = .iOS
private let appDeploymentTargets: DeploymentTargets = .iOS("17.0")

private func bundleId(_ name: String) -> String {
    "\(bundlePrefix).\(name.lowercased())"
}

// MARK: - 모듈 템플릿
//
// 레이어별로 타겟 구성이 정해져 있어 각 `Project.swift` 는 이름과 의존만 넘기면 된다.
//   • core    : framework 1개 (Models, DesignSystemKit)
//   • client  : Interface + Live framework 2개
//   • feature : Feature + Testing + Tests + Example(app) 4개
public extension Project {
    /// Core/Shared 모듈 — framework 1개.
    static func core(
        name: String,
        hasResources: Bool = false,
        dependencies: [TargetDependency] = []
    ) -> Project {
        let resources: ResourceFileElements? = hasResources ? ["Resources/**"] : nil
        return Project(
            name: name,
            settings: .standard,
            targets: [
                .target(
                    name: name,
                    destinations: appDestinations,
                    product: .framework,
                    bundleId: bundleId(name),
                    deploymentTargets: appDeploymentTargets,
                    sources: ["Sources/**"],
                    resources: resources,
                    scripts: [.swiftLint],
                    dependencies: dependencies
                )
            ]
        )
    }

    /// Client 모듈 — `{name}Interface` + `{name}Live`.
    /// `name` 은 "UserClient" 처럼 Client 접미사를 포함한 풀네임.
    static func client(
        name: String,
        interfaceDependencies: [TargetDependency] = [],
        liveDependencies: [TargetDependency] = []
    ) -> Project {
        let interface = "\(name)Interface"
        let live = "\(name)Live"
        return Project(
            name: name,
            settings: .standard,
            targets: [
                .target(
                    name: interface,
                    destinations: appDestinations,
                    product: .framework,
                    bundleId: bundleId(interface),
                    deploymentTargets: appDeploymentTargets,
                    sources: ["Interface/**"],
                    scripts: [.swiftLint],
                    dependencies: [.composableArchitecture, .models] + interfaceDependencies
                ),
                .target(
                    name: live,
                    destinations: appDestinations,
                    product: .framework,
                    bundleId: bundleId(live),
                    deploymentTargets: appDeploymentTargets,
                    sources: ["Live/**"],
                    dependencies: [.target(name: interface), .composableArchitecture, .models] + liveDependencies
                )
            ]
        )
    }

    /// Feature 모듈 — `{name}Feature` + `{name}FeatureTesting` + `{name}FeatureTests` + `{name}FeatureExample`(app).
    /// `name` 은 "Users" 처럼 Feature 접미사를 뺀 도메인 이름.
    static func feature(
        name: String,
        dependencies: [TargetDependency] = [],
        exampleDependencies: [TargetDependency] = []
    ) -> Project {
        let feature = "\(name)Feature"
        let testing = "\(feature)Testing"
        let tests = "\(feature)Tests"
        let example = "\(feature)Example"
        return Project(
            name: feature,
            settings: .standard,
            targets: [
                .target(
                    name: feature,
                    destinations: appDestinations,
                    product: .framework,
                    bundleId: bundleId(feature),
                    deploymentTargets: appDeploymentTargets,
                    sources: ["Sources/**"],
                    scripts: [.swiftLint],
                    dependencies: [.composableArchitecture, .designSystemKit] + dependencies
                ),
                .target(
                    name: testing,
                    destinations: appDestinations,
                    product: .framework,
                    bundleId: bundleId(testing),
                    deploymentTargets: appDeploymentTargets,
                    sources: ["Testing/**"],
                    dependencies: [.target(name: feature)]
                ),
                .target(
                    name: tests,
                    destinations: appDestinations,
                    product: .unitTests,
                    bundleId: bundleId(tests),
                    deploymentTargets: appDeploymentTargets,
                    sources: ["Tests/**"],
                    dependencies: [
                        .target(name: feature),
                        .target(name: testing),
                        .composableArchitecture
                    ]
                ),
                .target(
                    name: example,
                    destinations: appDestinations,
                    product: .app,
                    bundleId: bundleId(example),
                    deploymentTargets: appDeploymentTargets,
                    infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
                    sources: ["Example/**"],
                    dependencies: [.target(name: feature)] + exampleDependencies
                )
            ],
            schemes: [
                // Feature 단독 실행용 Example 앱 스킴.
                .scheme(
                    name: example,
                    shared: true,
                    buildAction: .buildAction(targets: ["\(example)"]),
                    runAction: .runAction(configuration: .configuration("Dev"), executable: "\(example)")
                )
            ]
        )
    }
}
