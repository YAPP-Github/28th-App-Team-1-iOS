import ProjectDescription
import DependencyPlugin

// MARK: - Environment

public extension Project {
    enum Environment {
        public static let appName = "App"
        public static let bundlePrefix = "com.yapp01.app"
        public static let destinations: Destinations = .iOS
        public static let deploymentTarget: DeploymentTargets = .iOS("26.0")
    }
}

// MARK: - Settings

public extension Settings {
    static var standard: Settings {
        .settings(
            base: ["GENERATE_INFOPLIST_FILE": "YES"],
            configurations: [
                .debug(name: "Dev", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEV"]),
                .debug(name: "QA"),
                .release(name: "Release")
            ]
        )
    }
}

// MARK: - Project

public extension Project {
    static func makeModule(
        name: String,
        targets: [Target],
        schemes: [Scheme] = []
    ) -> Self {
        .init(
            name: name,
            settings: .standard,
            targets: targets,
            schemes: schemes
        )
    }
}
