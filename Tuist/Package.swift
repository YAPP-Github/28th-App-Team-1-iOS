// swift-tools-version: 5.10
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "ComposableArchitecture": .framework,
            "KakaoSDKCommon": .framework,
            "KakaoSDKAuth": .framework,
            "KakaoSDKUser": .framework
            // Firebase 는 의도적으로 미지정(기본 static link) — dynamic 강제 시 공유 static 의존
            // (GoogleUtilities 등)이 여러 framework 에 중복 임베드돼 런타임 중복 클래스 경고가 난다.
            // static 링크의 -ObjC(카테고리 적재) 요구는 App 의 -all_load(D4)가 함께 충족한다.
        ],
        // 외부 SPM 의존도 워크스페이스와 동일한 3단계 Configuration 으로 생성한다.
        // (없으면 Debug/Release 로 생성돼 Dev/QA 빌드에서 구성 불일치 경고·폴백이 난다)
        baseSettings: .settings(
            configurations: [
                .debug(name: "Dev"),
                .release(name: "QA"),   // 워크스페이스와 동일하게 QA 도 release 타입
                .release(name: "Release")
            ]
        )
    )
#endif

let package = Package(
    name: "App",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.0"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.22.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0")
    ]
)
