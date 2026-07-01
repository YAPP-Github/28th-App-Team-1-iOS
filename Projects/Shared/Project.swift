import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

// Shared umbrella dependencies 는 ModulePath.Shared 를 순회해 자동 생성된다.
// 새 서브모듈 추가 시 Modules.swift 에 case 만 추가하면 여기 손댈 필요 없다.
let project = Project.makeModule(
    name: "Shared",
    targets: [
        .shared(factory: .init(dependencies: ModulePath.Shared.allCases.map {
            .project(target: "Shared\($0.rawValue)Implementation", path: .shared($0))
        }))
    ]
)
