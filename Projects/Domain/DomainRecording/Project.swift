import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.makeModule(
    name: "DomainRecording",
    targets: [
        .domain(interface: "Recording", factory: .init(dependencies: [
            .composableArchitecture   // Client 계약 + CameraPreviewHandle 이 TCA Dependency/AVFoundation 사용
        ])),
        .domain(implements: "Recording", factory: .init(dependencies: [
            .composableArchitecture   // liveValue — AVCaptureSession 소유 (서버 IO 없음)
        ])),
        .domain(testing: "Recording"),
        .domain(tests: "Recording")
    ]
)
