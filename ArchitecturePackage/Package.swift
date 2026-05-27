// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ArchitecturePackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "DesignSystemKit", targets: ["DesignSystemKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0")
    ],
    targets: [
        // ── Domain ────────────────────────────────────────────
        .target(name: "Models"),

        // ── Design System (임시 격리 / 색상·타이포·컴포넌트) ──
        .target(
            name: "DesignSystemKit",
            resources: [.process("Resources")]
        ),

        // ── Clients (interface + impl 한 모듈 / Stage 2) ─────
        .target(
            name: "UserClient",
            dependencies: [
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ProfileClient",
            dependencies: [
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),

        // ── Features ──────────────────────────────────────────
        .target(
            name: "HomeFeature",
            dependencies: [
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ActivityFeature",
            dependencies: [
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ProfileFeature",
            dependencies: [
                "Models",
                "ProfileClient",
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "UserFeature",
            dependencies: [
                "Models",
                "UserClient",
                "ProfileFeature",
                "DesignSystemKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),

        // ── App composition ──────────────────────────────────
        .target(
            name: "AppFeature",
            dependencies: [
                "HomeFeature",
                "UserFeature",
                "ActivityFeature",
                "ProfileFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
