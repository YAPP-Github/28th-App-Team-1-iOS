import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Users",
    dependencies: [.clientInterface("User"), .models],
    exampleDependencies: [.clientLive("User")]
)
