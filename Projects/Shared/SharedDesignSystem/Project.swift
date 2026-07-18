import ProjectDescription
import ProjectDescriptionHelpers

// 디자인 토큰(타이포그래피 등)은 상수 계약이라 전부 Interface 에 산다.
// 폰트 리소스(Pretendard otf)도 토큰이 직접 등록하므로 Interface 번들에 싣는다.
let project = Project.makeModule(
    name: "SharedDesignSystem",
    targets: [
        .shared(interface: "DesignSystem", factory: .init(resources: ["Interface/Resources/**"])),
        .shared(implements: "DesignSystem"),
        .shared(testing: "DesignSystem"),
        .shared(tests: "DesignSystem")
    ]
)
