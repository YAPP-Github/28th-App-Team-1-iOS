import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "App",
    targets: [
        .app(factory: .init(dependencies: [
    .core, .domain, .feature, .shared,
    .composableArchitecture,
]))
    ]
)
