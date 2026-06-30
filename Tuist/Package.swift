// swift-tools-version: 5.10
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "ComposableArchitecture": .framework
        ],
        // 외부 SPM 의존도 워크스페이스와 동일한 3단계 Configuration 으로 생성한다.
        // (없으면 Debug/Release 로 생성돼 Dev/QA 빌드에서 구성 불일치 경고·폴백이 난다)
        baseSettings: .settings(
            configurations: [
                .debug(name: "Dev"),
                .debug(name: "QA"),
                .release(name: "Release")
            ]
        )
    )
#endif

let package = Package(
    name: "App",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.0")
    ]
)
