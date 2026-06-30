import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Users",
    dependencies: [.domainInterface("User"), .domainInterface("Profile")],
    exampleDependencies: [.domainLive("User")]
)
