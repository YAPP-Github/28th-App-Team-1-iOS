import ProjectDescription
import ProjectDescriptionHelpers

// 전 `*ClientLive` 가 공유하는 순수 transport 인프라.
// baseURL·도메인을 모르며(환경 무지), 의존은 @Dependency 구성을 위한 TCA 뿐.
let project = Project.core(name: "Networking", dependencies: [.composableArchitecture])
