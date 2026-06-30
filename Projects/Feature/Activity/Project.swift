import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Activity",
    dependencies: [.domainInterface("Activity")],
    exampleDependencies: [.domainLive("Activity")]
)
