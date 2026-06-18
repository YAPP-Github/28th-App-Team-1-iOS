# 개발계 / 운영계 환경 분리

이 프로젝트는 **빌드 Configuration 기반**으로 개발계(dev)·운영계(prod)를 나눈다.
환경 분기는 **App(composition root)과 `*ClientLive` 만의 관심사**이고, Feature 는 환경을 전혀 모른다.

> 핵심: 환경값은 `@Dependency(\.appConfig)` 하나로 주입된다. `#if DEBUG` 를 코드 곳곳에 뿌리지 않는다.

---

## 한눈에

```
Config/Dev.xcconfig  ·  Config/Prod.xcconfig      (개발계 / 운영계 값)
        │  빌드 시 치환
        ▼
App Info.plist  ($(APP_ENV), $(API_BASE_URL), …)
        │  AppConfig.fromBundle()
        ▼
@Dependency(\.appConfig)  ──→  App(실행 로그) · *ClientLive(baseURL 선택)
        ✗
   *Feature 는 안 본다 (환경 무관)
```

| 스킴 | Configuration | APP_ENV | API_BASE_URL | bundle ID |
|---|---|---|---|---|
| `Architecture-Dev` | Debug | `dev` | `https://dev-api.architecture.com` | `com.architecture.app.dev` |
| `Architecture-Prod` | Release | `prod` | `https://api.architecture.com` | `com.architecture.app` |

Configuration 이름을 `Debug`/`Release` 로 유지하는 이유: Tuist 워크스페이스 안의 모든 프로젝트가
같은 Configuration 이름을 가져야 하기 때문. (커스텀 이름을 쓰려면 전 모듈에 동일하게 선언해야 함)

bundle ID·표시 이름이 환경별로 달라 **한 기기에 dev/prod 동시 설치** 가능하다.

---

## 쓰는 법

- **계 전환** = Xcode 스킴 토글 (`Architecture-Dev` ↔ `Architecture-Prod`).
- CLI:
  ```bash
  xcodebuild -workspace Architecture.xcworkspace -scheme Architecture-Prod \
    -destination 'generic/platform=iOS Simulator' build
  ```
- 실행하면 콘솔에 `🚀 환경=dev baseURL=…` 가 찍혀 어느 계인지 바로 확인된다.

## 값 추가하기 (예: 새 API 키)

1. `Projects/App/Config/Dev.xcconfig` · `Prod.xcconfig` 에 키 추가 (`SOME_KEY = …`)
2. `Projects/App/Project.swift` 의 `infoPlist` 에 `"SOME_KEY": "$(SOME_KEY)"` 치환 추가
3. `Projects/Shared/AppConfig/Sources/AppConfig.swift` 의 `fromBundle()` 에서 읽어 프로퍼티로 노출
4. `tuist generate`

## 새 Client 를 환경에 연결하기

```swift
// Projects/Client/XxxClient/Project.swift
let project = Project.client(name: "XxxClient", liveDependencies: [.appConfig])
```
```swift
// Live 에서
@Dependency(\.appConfig) var config
let url = config.baseURL.appendingPathComponent("…")
```

## 테스트에서 환경 갈아끼우기

```swift
withDependencies {
    $0.appConfig = AppConfig(environment: .prod, baseURL: URL(string: "https://api.architecture.com")!)
} operation: {
    // …
}
```
static 상수 대신 `@Dependency` 로 감싼 이유가 이것 — 테스트·프리뷰에서 환경을 자유롭게 주입.

---

## 관련 파일

- `Projects/Shared/AppConfig/` — 환경 타입 + Dependency
- `Projects/App/Config/{Dev,Prod}.xcconfig` — 환경값
- `Projects/App/Project.swift` — Configuration 연결 + Info.plist 치환 + Dev/Prod 스킴
- `Projects/Client/*/Live/*+Live.swift` — `config.baseURL` 소비
