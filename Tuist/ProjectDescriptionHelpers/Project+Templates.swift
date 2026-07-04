import ProjectDescription
import DependencyPlugin

// MARK: - Environment

public extension Project {
    enum Environment {
        public static let appName = "App"
        public static let bundlePrefix = "com.yapp01.app"
        public static let destinations: Destinations = .iOS
        public static let deploymentTarget: DeploymentTargets = .iOS("26.0")

        /// 로컬 `tuist generate` 는 기본값(동적) — 개발 중 SwiftUI Previews/컴파일 속도.
        /// 릴리스·CI 아카이브에서만 `TUIST_PRODUCT_TYPE=static-library tuist generate` 로 명시 전환.
        /// → Tuist TMA 공식 권장(dynamic in dev, static in release)
        public static var productType: ProjectDescription.Product {
            if case let .string(value) = ProjectDescription.Environment.productType {
                return value == "static-library" ? .staticLibrary : .framework
            }
            return .framework
        }
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
