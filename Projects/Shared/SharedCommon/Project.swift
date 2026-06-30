import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "SharedCommon",
    targets: [
        .shared(interface: "Common"),
        .shared(implements: "Common"),
        .shared(testing: "Common"),
        .shared(tests: "Common"),
    ]
)
