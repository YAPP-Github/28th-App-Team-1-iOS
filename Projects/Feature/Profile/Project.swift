import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Profile",
    dependencies: [.clientInterface("Profile"), .models],
    exampleDependencies: [.clientLive("Profile")]
)
