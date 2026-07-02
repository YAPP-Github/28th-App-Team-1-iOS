# 환경 분리 (Dev / QA / Release)

빌드 Configuration 기반으로 개발계(dev)·QA·운영계(release)를 나누는 방법.

## Overview

환경 분기는 **composition root(App)와 Domain `Implementation`(`liveValue`)만의 관심사**다. Feature 는 환경을 전혀 모른다 — Domain 의 `Interface` 계약만 의존하기 때문이다(<doc:ModularArchitecture> 의 두 번째 분리 규칙). 그래서 계를 추가해도 Feature·다른 레이어 코드는 한 줄도 바뀌지 않는다.

환경값은 `@Dependency(\.appConfig)` 하나로 주입하는 것을 지향한다. `#if DEBUG` 를 코드 곳곳에 뿌리지 않는다.

```text
App/Config/Dev.xcconfig · QA.xcconfig · Prod.xcconfig   (계별 값)
        │  빌드 시 치환
        ▼
App Info.plist  ($(APP_ENV), $(API_BASE_URL), …)
        │  AppConfig.fromBundle()
        ▼
@Dependency(\.appConfig)  ──▶  App(실행 로그) · Domain Implementation(baseURL 선택)
        ✗
   Feature 는 안 본다 (환경 무관)
```

> **현재 상태**: `refactor/#6` 골격에는 **3개 빌드 Configuration(Dev/QA/Release)** 과 `App/Config/*.xcconfig` 스캐폴드까지 들어있다. `AppConfig` 주입 모듈·Info.plist 치환·계별 스킴은 **이관 대기**다 — 아래는 그 목표 형태와, 지금 실재하는 골격을 함께 정리한다.

## 지금 실재하는 것 — 3 Configuration

Tuist 는 워크스페이스 내 모든 프로젝트가 **같은 Configuration 집합**을 갖길 요구한다. 그래서 이름은 `Tuist/ProjectDescriptionHelpers/Project+Templates.swift` 의 `Settings.standard` **한 곳**에서 정의해 전 모듈이 공유한다.

| Configuration | 타입 | 컴파일 조건 | 용도 |
|---|---|---|---|
| `Dev` | debug | `+ DEV` | 개발계 — 디버그 표면 노출 |
| `QA` | debug | — | 테스터 배포 (디버그 메뉴 없음) |
| `Release` | release | — | 운영계 |

`Dev` 에만 `SWIFT_ACTIVE_COMPILATION_CONDITIONS` 에 `DEV` 가 들어간다. 디버그 전용 코드는 `#if DEV` 로 감싸 **QA·Release 바이너리엔 코드 자체가 존재하지 않게** 한다(런타임 플래그가 아니라 컴파일 타임 제거 → 운영 빌드에 디버그 표면이 새지 않음).

## 목표 형태 — 값 주입 (이관 시)

계별 값(`API_BASE_URL` 등)을 `@Dependency(\.appConfig)` 로 흘리는 패턴. 모듈 배치는 TMA 를 따른다:

- `Shared/SharedAppConfig` (또는 Core 인프라 모듈) — `AppConfig` 타입 + `.dev`/`.qa`/`.prod` Dependency. `Interface` 에 타입, `Implementation` 에 `fromBundle()`.
- `Core/CoreNetwork` — 순정 `URLSession` transport(`APIClient`). baseURL·도메인은 모른다.
- Domain `Implementation`(`liveValue`)이 `@Dependency(\.appConfig)` 로 baseURL 을 받아 path 를 조립한다.

```swift
// Domain Implementation 의 liveValue — Interface·Feature 는 그대로 환경 무관
@Dependency(\.appConfig) var config   // baseURL (계 선택)
@Dependency(\.apiClient) var api      // CoreNetwork transport
return ProfileClient(
    fetchProfile: { id in try await api.decoded(Profile.self, baseURL: config.baseURL, .init(path: "/profile/\(id)")) }
)
```

> Important: `.shared(interface: .appConfig)` · `.core(interface: .network)` 는 **Domain Implementation·App 에만** 넣는다. Feature 나 Interface 에 넣으면 "Feature 는 환경 무관" 규칙이 깨진다.

## 값 추가하기 (이관 후)

1. `Projects/App/Config/Dev.xcconfig` · `QA.xcconfig` · `Prod.xcconfig` 에 키 추가 (`SOME_KEY = …`)
2. `Projects/App/Project.swift` 의 `infoPlist` 에 `"SOME_KEY": "$(SOME_KEY)"` 치환 추가
3. `AppConfig` 의 `fromBundle()` 에서 읽어 프로퍼티로 노출
4. `tuist generate`

> Tip: xcconfig 값에 URL 처럼 `//` 가 들어가면 주석으로 먹힌다. `https:/$()/host` 처럼 빈 변수 `$()` 를 끼워 회피한다.

## 테스트·프리뷰에서 환경 주입

static 상수가 아니라 `@Dependency` 로 감싸면 테스트·프리뷰에서 환경을 자유롭게 갈아끼운다.

```swift
withDependencies {
    $0.appConfig = AppConfig(environment: .prod, baseURL: URL(string: "https://api.example.com")!)
} operation: {
    // 운영계 가정 하에 reducer 테스트
}
```

## 관련 파일

- `Tuist/ProjectDescriptionHelpers/Project+Templates.swift` — `Settings.standard` (워크스페이스 전역 3 Configuration)
- `Projects/App/Config/{Dev,QA,Prod}.xcconfig` — 계별 값 (스캐폴드)
- `Projects/App/Project.swift` — Configuration 연결 + (이관 시) Info.plist 치환

## See Also

- <doc:ModularArchitecture>
- <doc:AddingFeature>
