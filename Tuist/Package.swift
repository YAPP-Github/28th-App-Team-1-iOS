// swift-tools-version: 5.10
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "ComposableArchitecture": .framework,
            "DesignSystemKit": .framework
        ]
    )
#endif

let package = Package(
    name: "Architecture",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0"),
        .package(path: "../ArchitecturePackage")
    ]
)
