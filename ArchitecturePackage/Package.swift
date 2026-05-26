// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ArchitecturePackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0")
    ],
    targets: [
        // ── Domain ────────────────────────────────────────────
        .target(name: "Models"),

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
            name: "UserListFeature",
            dependencies: [
                "Models",
                "UserClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "UserDetailFeature",
            dependencies: [
                "Models",
                "UserClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ProfileFeature",
            dependencies: [
                "Models",
                "ProfileClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),

        // ── App composition ──────────────────────────────────
        .target(
            name: "AppFeature",
            dependencies: [
                "UserListFeature",
                "UserDetailFeature",
                "ProfileFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
