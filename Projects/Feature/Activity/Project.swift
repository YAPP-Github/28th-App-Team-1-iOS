import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Activity",
    dependencies: [.clientInterface("Activity"), .models],
    exampleDependencies: [.clientLive("Activity")]
)
