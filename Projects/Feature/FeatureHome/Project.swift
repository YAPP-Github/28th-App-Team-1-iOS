import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

// MARK: - ⚠️ 수동 작업 필요 (아래 두 파일을 직접 수정하세요)
//
// 1. Plugins/DependencyPlugin/ProjectDescriptionHelpers/Modules.swift
//    ModulePath.Feature enum에 신규 case를 추가합니다:
//    case home = "Home"
//
// 2. Projects/Feature/Project.swift (Feature umbrella 타겟)
//    dependencies 배열에 아래 항목을 추가합니다:
//    .project(target: "FeatureHomeImplementation", path: "FeatureHome")

let project = Project.makeModule(
    name: "FeatureHome",
    targets: [
        .feature(interface: "Home"),
        .feature(implements: "Home", factory: .init(dependencies: [
            .composableArchitecture,
        ])),
        .feature(testing: "Home"),
        .feature(tests: "Home"),
        .feature(example: "Home"),
    ]
)
