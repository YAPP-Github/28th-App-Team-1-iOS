import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Core",
    targets: [
        .core(factory: .init(dependencies: [
            .project(target: "CoreCommonImplementation", path: "CoreCommon"),
        ]))
    ]
)
