import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "FeatureReels",
    targets: [
        // D3: Feature 는 Interface 를 두지 않는다 (단일 Implementation). → DocC FeatureInterface / architecture.md D3
        .feature(implements: "Reels", factory: .init(dependencies: [
            .composableArchitecture
        ])),
        .feature(testing: "Reels"),
        .feature(tests: "Reels"),
        // Example 에만 샘플 영상(reel_sample.mp4) 번들 — factory.resources 사용(헬퍼 수정 불필요)
        .feature(example: "Reels", factory: .init(resources: ["Example/Resources/**"]))
    ]
)
