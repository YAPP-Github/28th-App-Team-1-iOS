import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Feature",
    targets: [
        .feature(factory: .init(dependencies: [
            .project(target: "FeatureCommonImplementation", path: "FeatureCommon"),
        ]))
    ]
)
