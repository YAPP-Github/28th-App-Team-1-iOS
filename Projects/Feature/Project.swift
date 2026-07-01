import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

// Feature umbrella dependencies 는 ModulePath.Feature 를 순회해 자동 생성된다.
// 새 서브모듈 추가 시 Modules.swift 에 case 만 추가하면 여기 손댈 필요 없다.
let project = Project.makeModule(
    name: "Feature",
    targets: [
        .feature(factory: .init(dependencies: ModulePath.Feature.allCases.map {
            .project(target: "Feature\($0.rawValue)Implementation", path: .feature($0))
        }))
    ]
)
