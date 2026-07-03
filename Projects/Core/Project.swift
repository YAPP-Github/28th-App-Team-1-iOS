import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

// Core umbrella dependencies 는 ModulePath.Core 를 순회해 자동 생성된다.
// 새 서브모듈 추가 시 Modules.swift 에 case 만 추가하면 여기 손댈 필요 없다.
let project = Project.makeModule(
    name: "Core",
    targets: [
        .core(factory: .init(dependencies: ModulePath.Core.allCases.map {
            .project(target: "Core\($0.rawValue)Implementation", path: .core($0))
        }))
    ]
)
