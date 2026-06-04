// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ArchitecturePackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DesignSystemKit", targets: ["DesignSystemKit"]),
        .library(name: "UserFeature", targets: ["UserFeature"]),
        .library(name: "ActivityFeature", targets: ["ActivityFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0")
    ],
    targets: [
        // ── Core ──────────────────────────────────────────────
        .target(
            name: "Models",
            path: "Sources/Core/Models"
        ),
        .target(
            name: "DesignSystemKit",
            path: "Sources/Core/DesignSystemKit",
            resources: [.process("Resources")]
        ),

        // ── Data (Clients) ────────────────────────────────────
        .target(
            name: "UserClient",
            dependencies: [
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Data/UserClient"
        ),
        .target(
            name: "ProfileClient",
            dependencies: [
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Data/ProfileClient"
        ),

        // ── Feature ───────────────────────────────────────────
        .target(
            name: "ActivityFeature",
            dependencies: [
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Feature/ActivityFeature"
        ),
        .target(
            name: "ProfileFeature",
            dependencies: [
                "Models",
                "ProfileClient",
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Feature/ProfileFeature"
        ),
        .target(
            name: "UserFeature",
            dependencies: [
                "Models",
                "UserClient",
                "ProfileFeature",
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Feature/UserFeature"
        )
    ]
)
