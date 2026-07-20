import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "CorePush",
    targets: [
        .core(interface: "Push", factory: .init(dependencies: [
            .composableArchitecture   // PushClient 계약이 TestDependencyKey/DependencyValues 를 사용
        ])),
        .core(implements: "Push", factory: .init(dependencies: [
            .composableArchitecture,
            // Firebase SDK 는 이 Implementation 안에만 존재한다 — Interface·Feature·App 은 SDK 를 모른다.
            .firebaseCore,
            .firebaseMessaging
        ])),
        .core(testing: "Push"),
        .core(tests: "Push", factory: .init(dependencies: [
            .composableArchitecture
        ]))
    ]
)
