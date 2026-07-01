import ProjectDescription

private let nameAttribute = Template.Attribute.required("name")

private let template = Template(
    description: "Shared 모듈 전체 scaffold (TMA 4-layer). 사용: tuist scaffold Shared --name DesignSystem",
    attributes: [nameAttribute],
    items: [
        .file(
            path: "Projects/Shared/Shared\(nameAttribute)/Interface/Shared\(nameAttribute)Interface.swift",
            templatePath: "SharedInterface.stencil"
        ),
        .file(
            path: "Projects/Shared/Shared\(nameAttribute)/Sources/Shared\(nameAttribute)Implementation.swift",
            templatePath: "SharedSources.stencil"
        ),
        .file(
            path: "Projects/Shared/Shared\(nameAttribute)/Testing/Shared\(nameAttribute)Testing.swift",
            templatePath: "SharedTesting.stencil"
        ),
        .file(
            path: "Projects/Shared/Shared\(nameAttribute)/Tests/Shared\(nameAttribute)Tests.swift",
            templatePath: "SharedTests.stencil"
        ),
        .file(
            path: "Projects/Shared/Shared\(nameAttribute)/Project.swift",
            templatePath: "SharedProject.stencil"
        ),
    ]
)
