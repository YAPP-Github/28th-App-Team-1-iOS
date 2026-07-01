import ProjectDescription

private let nameAttribute = Template.Attribute.required("name")

private let template = Template(
    description: "Feature 모듈 전체 scaffold (TMA 4-layer, TCA + SwiftUI). 사용: tuist scaffold Feature --name Home",
    attributes: [nameAttribute],
    items: [
        .file(
            path: "Projects/Feature/Feature\(nameAttribute)/Interface/Feature\(nameAttribute)Interface.swift",
            templatePath: "FeatureInterface.stencil"
        ),
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
