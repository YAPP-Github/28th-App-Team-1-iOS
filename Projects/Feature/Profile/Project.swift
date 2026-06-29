import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Profile",
    dependencies: [.domainInterface("Profile")],
    exampleDependencies: [.domainLive("Profile")]
)
