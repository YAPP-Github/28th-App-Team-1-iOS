import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Shared",
    targets: [
        .shared(factory: .init(dependencies: [
            .project(target: "SharedCommonImplementation", path: "SharedCommon"),
        ]))
    ]
)
