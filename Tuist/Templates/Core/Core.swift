import ProjectDescription

private let nameAttribute = Template.Attribute.required("name")

private let template = Template(
    description: "Core 모듈 전체 scaffold (TMA 4-layer). 사용: tuist scaffold Core --name Network",
    attributes: [nameAttribute],
    items: [
        .file(
            path: "Projects/Core/Core\(nameAttribute)/Interface/Core\(nameAttribute)Interface.swift",
            templatePath: "CoreInterface.stencil"
        ),
        .file(
            path: "Projects/Core/Core\(nameAttribute)/Sources/Core\(nameAttribute)Implementation.swift",
            templatePath: "CoreSources.stencil"
        ),
        .file(
            path: "Projects/Core/Core\(nameAttribute)/Testing/Core\(nameAttribute)Testing.swift",
            templatePath: "CoreTesting.stencil"
        ),
        .file(
            path: "Projects/Core/Core\(nameAttribute)/Tests/Core\(nameAttribute)Tests.swift",
            templatePath: "CoreTests.stencil"
        ),
        .file(
            path: "Projects/Core/Core\(nameAttribute)/Project.swift",
            templatePath: "CoreProject.stencil"
        ),
    ]
)
