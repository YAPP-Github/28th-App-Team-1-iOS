# 환경 분리 (Dev / QA / Release)

빌드 Configuration 기반으로 개발계(dev)·QA·운영계(release)를 나누는 방법.

## Overview

환경 분기는 **`AppConfig`(composition root)와 `*ClientLive` 만의 관심사**다. Feature 는 환경을 전혀 모른다 — `*ClientInterface` 만 의존하기 때문이다(<doc:ModularArchitecture> 의 두 번째 분리 규칙). 그래서 계를 추가해도 Feature 코드는 한 줄도 바뀌지 않는다.

환경값은 `@Dependency(\.appConfig)` 하나로 주입된다. `#if DEBUG` 를 코드 곳곳에 뿌리지 않는다.

```text
Config/Dev.xcconfig · QA.xcconfig · Prod.xcconfig   (계별 값)
        │  빌드 시 치환
        ▼
App Info.plist  ($(APP_ENV), $(API_BASE_URL), …)
        │  AppConfig.fromBundle()
        ▼
@Dependency(\.appConfig)  ──▶  App(실행 로그) · *ClientLive(baseURL 선택)
        ✗
   *Feature 는 안 본다 (환경 무관)
```

| 스킴 | Configuration | 타입 | APP_ENV | API_BASE_URL | bundle ID |
|---|---|---|---|---|---|
| `Architecture-Dev` | Dev | debug `+ DEV` | `dev` | `https://dev-api.architecture.com` | `…app.dev` |
| `Architecture-QA` | QA | debug | `qa` | `https://dev-api.architecture.com` | `…app.qa` |
| `Architecture-Prod` | Release | release | `prod` | `https://api.architecture.com` | `…app` |

QA 는 **개발계 서버를 그대로 보되 디버그 메뉴는 없는** 테스터 배포용 계다. 그래서 `API_BASE_URL` 은 dev 와 같고, `DEV` 컴파일 조건만 빠진다(아래 «디버그 메뉴» 참조).

> Note: 2티어 시절엔 Configuration 이름을 기본값 `Debug`/`Release` 로 뒀지만, 3티어로 가며 의미가 분명한 `Dev`/`QA`/`Release` 로 바꿨다. Tuist 는 워크스페이스 내 모든 프로젝트가 **같은 Configuration 집합**을 갖길 요구하므로, 이름은 `Tuist/ProjectDescriptionHelpers` 의 `Settings.standard` 한 곳에서 정의해 전 모듈이 공유하고, 외부 SPM 의존도 `Tuist/Package.swift` 의 `PackageSettings.baseSettings` 로 같은 3집합을 받는다.

bundle ID·표시 이름이 계별로 달라 **한 기기에 dev/qa/release 동시 설치**가 된다.

## 디버그 메뉴 (Dev 전용)

Dev 구성에만 `SWIFT_ACTIVE_COMPILATION_CONDITIONS` 에 `DEV` 가 들어간다. 디버그 메뉴는 통째로 `#if DEV` 로 감싸 **QA·Release 바이너리엔 코드 자체가 존재하지 않는다**(런타임 플래그가 아니라 컴파일 타임 제거 → 운영 빌드에 디버그 표면이 새지 않음).

위치는 composition root(`Projects/App/Sources/DebugMenu.swift`) 한 곳 — Feature 는 환경을 모른다는 규칙을 깨지 않기 위해서다. `AppView` 위에 떠 있는 버튼(🐞)을 눌러 시트로 연다. 현재 제공: 환경 배너, 탭 점프, 앱 데이터(UserDefaults·URLCache·Caches) 전체 삭제.

> Note: 폼 자동입력·자동 진행 같은 **화면 내부** 디버그 훅은 Feature 의 협조가 필요해(환경 무관 규칙과 충돌) 이 메뉴에 넣지 않았다. 도입하려면 각 Feature 가 외부 주입 신호를 받는 별도 설계가 선행돼야 한다.

## 계 전환

Xcode 스킴 토글 — `Architecture-Dev` ↔ `Architecture-Prod`. 터미널:

```bash
xcodebuild -workspace Architecture.xcworkspace -scheme Architecture-Prod \
  -destination 'generic/platform=iOS Simulator' build
```

실행하면 콘솔에 `🚀 환경=dev baseURL=…` 가 찍혀 어느 계로 떴는지 바로 확인된다.

## 값 추가하기

새 환경값(예: API 키)을 더할 때:

1. `Projects/App/Config/Dev.xcconfig` · `QA.xcconfig` · `Prod.xcconfig` 에 키 추가 (`SOME_KEY = …`)
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
@Dependency(\.appConfig) var config   // baseURL (계 선택)
@Dependency(\.apiClient) var api      // 순정 URLSession transport (Networking 모듈)
return XxxClient(
    fetch: { try await api.decoded(Xxx.self, baseURL: config.baseURL, .init(path: "…")) }
)
```

실제 HTTP 는 `Networking` 코어 모듈의 `APIClient`(순정 `URLSession`)가 담당한다 — `*ClientLive` 는 baseURL 만 주입하고 path 를 조립한다. Networking 자체는 baseURL·도메인을 모른다. Live 에 `.networking` 의존을 추가한다(`liveDependencies: [.appConfig, .networking]`).

> Important: `.appConfig` · `.networking` 는 **Live 에만** 넣는다. Interface 나 Feature 에 넣으면 "Feature 는 환경 무관" 규칙이 깨진다.

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

- `Projects/Shared/AppConfig/` — `AppConfig` 타입 + Dependency (`.dev` / `.qa` / `.prod`)
- `Projects/Shared/Networking/` — 순정 URLSession `APIClient` (전 `*ClientLive` 공유 transport)
- `Projects/App/Config/{Dev,QA,Prod}.xcconfig` — 계별 값
- `Tuist/ProjectDescriptionHelpers/Project+Templates.swift` — `Settings.standard` (워크스페이스 전역 3 Configuration)
- `Projects/App/Project.swift` — Configuration 연결 + Info.plist 치환 + Dev/QA/Prod 스킴
- `Projects/App/Sources/DebugMenu.swift` — `#if DEV` 디버그 메뉴
- `Projects/Client/*/Live/*+Live.swift` — `config.baseURL` 소비

## See Also

- <doc:ModularArchitecture>
- <doc:AddingFeature>
- ``AppFeature``
