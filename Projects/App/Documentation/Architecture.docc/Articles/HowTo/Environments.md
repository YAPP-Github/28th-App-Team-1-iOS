# 개발계 / 운영계 환경 분리

빌드 Configuration 기반으로 개발계(dev)·운영계(prod)를 나누는 방법.

## Overview

환경 분기는 **`AppConfig`(composition root)와 `*ClientLive` 만의 관심사**다. Feature 는 환경을 전혀 모른다 — `*ClientInterface` 만 의존하기 때문이다(<doc:ModularArchitecture> 의 두 번째 분리 규칙). 그래서 운영계를 추가해도 Feature 코드는 한 줄도 바뀌지 않는다.

환경값은 `@Dependency(\.appConfig)` 하나로 주입된다. `#if DEBUG` 를 코드 곳곳에 뿌리지 않는다.

```text
Config/Dev.xcconfig · Config/Prod.xcconfig      (개발계 / 운영계 값)
        │  빌드 시 치환
        ▼
App Info.plist  ($(APP_ENV), $(API_BASE_URL), …)
        │  AppConfig.fromBundle()
        ▼
@Dependency(\.appConfig)  ──▶  App(실행 로그) · *ClientLive(baseURL 선택)
        ✗
   *Feature 는 안 본다 (환경 무관)
```

| 스킴 | Configuration | APP_ENV | API_BASE_URL | bundle ID |
|---|---|---|---|---|
| `Architecture-Dev` | Debug | `dev` | `https://dev-api.architecture.com` | `com.architecture.app.dev` |
| `Architecture-Prod` | Release | `prod` | `https://api.architecture.com` | `com.architecture.app` |

> Note: Configuration 이름을 `Debug`/`Release` 로 유지하는 이유 — Tuist 워크스페이스 안의 모든 프로젝트가 같은 Configuration 이름을 가져야 한다. 커스텀 이름(`Dev`/`Prod`)을 쓰려면 전 모듈에 동일하게 선언해야 하므로, 2티어에선 기본 이름 재사용이 가장 가볍다.

bundle ID·표시 이름이 환경별로 달라 **한 기기에 dev/prod 동시 설치**가 된다.

## 계 전환

Xcode 스킴 토글 — `Architecture-Dev` ↔ `Architecture-Prod`. 터미널:

```bash
xcodebuild -workspace Architecture.xcworkspace -scheme Architecture-Prod \
  -destination 'generic/platform=iOS Simulator' build
```

실행하면 콘솔에 `🚀 환경=dev baseURL=…` 가 찍혀 어느 계로 떴는지 바로 확인된다.

## 값 추가하기

새 환경값(예: API 키)을 더할 때:

1. `Projects/App/Config/Dev.xcconfig` · `Prod.xcconfig` 에 키 추가 (`SOME_KEY = …`)
2. `Projects/App/Project.swift` 의 `infoPlist` 에 `"SOME_KEY": "$(SOME_KEY)"` 치환 추가
3. `AppConfig` 의 `fromBundle()` 에서 읽어 프로퍼티로 노출
4. `tuist generate`

> Tip: xcconfig 값에 URL 처럼 `//` 가 들어가면 주석으로 먹힌다. `https:/$()/host` 처럼 빈 변수 `$()` 를 끼워 회피한다.

## 새 Client 를 환경에 연결

```swift
// Projects/Client/XxxClient/Project.swift
let project = Project.client(name: "XxxClient", liveDependencies: [.appConfig])
```

```swift
// Live 에서 — Interface·Feature 는 그대로 환경 무관
@Dependency(\.appConfig) var config
let url = config.baseURL.appendingPathComponent("…")
```

> Important: `.appConfig` 는 **Live 에만** 넣는다. Interface 나 Feature 에 넣으면 "Feature 는 환경 무관" 규칙이 깨진다.

## 테스트·프리뷰에서 환경 주입

static 상수가 아니라 `@Dependency` 로 감싼 이유 — 테스트·프리뷰에서 환경을 자유롭게 갈아끼우기 위해서다.

```swift
withDependencies {
    $0.appConfig = AppConfig(environment: .prod, baseURL: URL(string: "https://api.architecture.com")!)
} operation: {
    // 운영계 가정 하에 reducer 테스트
}
```

## 관련 파일

- `Projects/Shared/AppConfig/` — `AppConfig` 타입 + Dependency
- `Projects/App/Config/{Dev,Prod}.xcconfig` — 환경값
- `Projects/App/Project.swift` — Configuration 연결 + Info.plist 치환 + Dev/Prod 스킴
- `Projects/Client/*/Live/*+Live.swift` — `config.baseURL` 소비

## See Also

- <doc:ModularArchitecture>
- <doc:AddingFeature>
- ``AppFeature``
