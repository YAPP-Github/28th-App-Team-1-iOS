import ProjectDescription
import DependencyPlugin

// MARK: - Environment

public extension Project {
    enum Environment {
        public static let appName = "Hilit"
        public static let bundlePrefix = "com.hilit.app"
        /// iPhone 전용 서비스 — iPad·Mac(Designed for iPad) 미지원 결정 (2026-07-15).
        public static let destinations: Destinations = [.iPhone]
        public static let deploymentTarget: DeploymentTargets = .iOS("17.0")

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
            base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                // 모든 모듈 framework 의 Info.plist 에 버전 키를 채운다 — dynamic 임베드 시
                // CFBundleShortVersionString 누락으로 인한 TestFlight 업로드 거부(90057)를 막는다.
                // (앱/Example 타겟은 자체 settings 의 버전으로 override 된다)
                "MARKETING_VERSION": "1.0.0",
                "CURRENT_PROJECT_VERSION": "1"
            ],
            configurations: [
                .debug(name: "Dev", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEV"]),
                // QA 는 테스터 배포용 — release 타입(최적화 -O·assert 제거)으로 실사용과 같은 동작을 빌드한다.
                .release(name: "QA"),
                .release(name: "Release")
            ]
        )
    }
}

// MARK: - Project

public extension Project {
    static func makeModule(
        name: String,
        options: Project.Options = .options(),
        targets: [Target],
        schemes: [Scheme] = []
    ) -> Self {
        .init(
            name: name,
            options: options,
            settings: .standard,
            targets: targets,
            schemes: schemes
        )
    }
}
