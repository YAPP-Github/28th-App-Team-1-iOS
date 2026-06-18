import ProjectDescription
import ProjectDescriptionHelpers

// Live 만 환경 설정(AppConfig)에 의존 — Interface·Feature 는 환경을 모른다.
let project = Project.client(name: "ActivityClient", liveDependencies: [.appConfig])
