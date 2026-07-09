import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "DomainAuth",
    targets: [
        .domain(interface: "Auth"),
        .domain(implements: "Auth", factory: .init()),
        .domain(testing: "Auth")
    ]
)
