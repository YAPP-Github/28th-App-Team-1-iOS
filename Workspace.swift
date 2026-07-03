import ProjectDescription

/// 모듈별 `Project.swift` 를 glob 으로 통합하는 루트 워크스페이스.
let workspace = Workspace(
    name: "App",
    projects: ["Projects/**"]
)
