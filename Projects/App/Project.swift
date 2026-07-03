import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "App",
    targets: [
        .app(factory: .init(dependencies: [
            .core, .domain, .feature, .shared,
            .composableArchitecture
        ])),
        // 전역 DocC 카탈로그 호스트 (코드 없음). Xcode: 스킴 ArchitectureDocs → Product → Build Documentation
        .docs(factory: .init(dependencies: [
            .core, .domain, .feature, .shared,
            .composableArchitecture
        ]))
    ],
    schemes: [
        .scheme(
            name: "ArchitectureDocs",
            shared: true,
            buildAction: .buildAction(targets: ["ArchitectureDocs"])
        )
    ]
)
