import ProjectDescription

private let nameAttribute = Template.Attribute.required("name")
private let authorAttribute = Template.Attribute.optional("author", default: .string("Unknown"))

private let template = Template(
    description: "Feature 모듈 전체 scaffold (TMA 4-layer, TCA + SwiftUI). 사용: make scaffold-feature name=Home (author 는 make 가 git config user.name 으로 자동 채움)",
    attributes: [nameAttribute, authorAttribute],
    items: [
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Sources/\(nameAttribute)Feature.swift",
            templatePath: "FeatureReducer.stencil"
        ),
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Sources/\(nameAttribute)View.swift",
            templatePath: "FeatureView.stencil"
        ),
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Testing/Feature\(nameAttribute)Testing.swift",
            templatePath: "FeatureTesting.stencil"
        ),
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Tests/Feature\(nameAttribute)Tests.swift",
            templatePath: "FeatureTests.stencil"
        ),
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Example/Feature\(nameAttribute)ExampleApp.swift",
            templatePath: "FeatureExample.stencil"
        ),
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Project.swift",
            templatePath: "FeatureProject.stencil"
        ),
    ]
)
