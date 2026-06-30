import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "Domain",
    targets: [
        .domain(factory: .init(dependencies: [
            .project(target: "DomainCommonImplementation", path: "DomainCommon"),
        ]))
    ]
)
