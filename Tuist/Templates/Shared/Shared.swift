import ProjectDescription

private let nameAttribute = Template.Attribute.required("name")
private let authorAttribute = Template.Attribute.optional("author", default: .string("Unknown"))

private let template = Template(
    description: "Shared 모듈 전체 scaffold (TMA 4-layer). 사용: make scaffold-shared name=DesignSystem (author 는 make 가 git config user.name 으로 자동 채움)",
    attributes: [nameAttribute, authorAttribute],
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
