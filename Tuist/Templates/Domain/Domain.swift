import ProjectDescription

private let nameAttribute = Template.Attribute.required("name")
private let authorAttribute = Template.Attribute.optional("author", default: .string("Unknown"))

private let template = Template(
    description: "Domain 모듈 전체 scaffold (TMA 4-layer). 사용: make scaffold-domain name=User (author 는 make 가 git config user.name 으로 자동 채움)",
    attributes: [nameAttribute, authorAttribute],
    items: [
        .file(
            path: "Projects/Domain/Domain\(nameAttribute)/Interface/Domain\(nameAttribute)Interface.swift",
            templatePath: "DomainInterface.stencil"
        ),
        .file(
            path: "Projects/Domain/Domain\(nameAttribute)/Sources/Domain\(nameAttribute)Implementation.swift",
            templatePath: "DomainSources.stencil"
        ),
        .file(
            path: "Projects/Domain/Domain\(nameAttribute)/Testing/Domain\(nameAttribute)Testing.swift",
            templatePath: "DomainTesting.stencil"
        ),
        .file(
            path: "Projects/Domain/Domain\(nameAttribute)/Tests/Domain\(nameAttribute)Tests.swift",
            templatePath: "DomainTests.stencil"
        ),
        .file(
            path: "Projects/Domain/Domain\(nameAttribute)/Project.swift",
            templatePath: "DomainProject.stencil"
        ),
    ]
)
