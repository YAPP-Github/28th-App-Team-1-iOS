// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ArchitecturePackage",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "DesignSystemKit", targets: ["DesignSystemKit"])
    ],
    targets: [
        .target(
            name: "Models",
            path: "Sources/Core/Models"
        ),
        .target(
            name: "DesignSystemKit",
            path: "Sources/Core/DesignSystemKit",
            resources: [.process("Resources")]
        )
    ]
)
