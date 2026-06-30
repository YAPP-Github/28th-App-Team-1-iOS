import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: "CoreCommon",
    targets: [
        .core(interface: "Common"),
        .core(implements: "Common"),
        .core(testing: "Common"),
        .core(tests: "Common"),
    ]
)
