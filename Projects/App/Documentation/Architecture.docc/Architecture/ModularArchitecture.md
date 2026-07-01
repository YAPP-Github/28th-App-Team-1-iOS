# Modular Architecture — 이 프로젝트의 위치

Tuist 로 project 자체를 모듈화한 TMA(The Modular Architecture) 안에서 이 프로젝트가 어디에 서 있는지.

## Overview

"모듈러 아키텍처" 라는 용어는 스펙트럼에 가깝다. 한쪽 끝에는 단일 target 에 폴더만 정리하는 일반 사이드 프로젝트가 있고, 반대쪽 끝에는 Tuist · Bazel 같은 빌드 도구로 project 자체를 모듈화한 초대형 앱이 있다.

이 프로젝트는 **Level 3+ (Tuist 멀티프로젝트 TMA)** 에 위치한다 — 레이어(`Core / Domain / Feature / Shared`)마다 독립된 Xcode project 로 분리하고, Domain·Core·Shared 는 각 모듈을 다시 `Interface`(계약) / `Implementation`(구현)으로 쪼갠다 (**Feature 는 단일 모듈** — D3). 하나의 Workspace 가 `Projects/**` 글롭으로 통합한다.

### 스펙트럼

| 수준 | 설명 | 이 프로젝트 |
|---|---|---|
| 1 | 단일 target + 폴더 정리 | ✗ |
| 2 | 단일 SPM 패키지 + 다중 target | ✗ |
| 3 | 빌드 도구(Tuist)로 project 자체 모듈화 — µFeature | ↑ (이전 단계) |
| **3+** | **위 + 모듈마다 Interface/Implementation 분리 (TMA / Clean)** | **여기** |
| 4 | 모노레포 + Bazel 등 (초대형) | ✗ (Lyft · Uber 등) |

### 왜 Tuist TMA 인가

`App` 앱 타겟은 얇게 두고, 실제 코드는 모두 레이어별 독립 모듈로 분리한다. 각 모듈은 자체 `Project.swift` 를 갖고, 루트 `Workspace.swift` 가 `Projects/**` 를 글롭으로 묶는다. `Project.swift` 는 레이어 팩토리 호출뿐이라 target 보일러플레이트가 없다.

```text
Workspace.swift                  # Projects/** 통합
Plugins/DependencyPlugin/        # ModulePath 레지스트리 + 경로·의존 액세서
Tuist/
  ├── Package.swift              # 외부 의존 (ComposableArchitecture)
  ├── ProjectDescriptionHelpers/ # Project.makeModule + Target 팩토리(.app/.core/.domain/.feature/.shared)
  └── Templates/                 # tuist scaffold 용 레이어별 스텐실
Projects/
  ├── App/                       # composition root (App @main + AppFeature + Config + Documentation)
  ├── Core/    {CoreCommon,…}     # 인프라 (네트워킹 등)
  ├── Domain/  {DomainCommon,…}                  # 도메인 모델 + Repository
  ├── Feature/ {FeatureCommon, FeatureHome,…}     # 화면 도메인 (단일 모듈)
  └── Shared/  {SharedCommon, SharedDesignSystem,…} # 디자인 토큰 등 공용
```

modular architecture 의 핵심 조건을 모두 만족한다:

- **모듈 경계 명시** — 각 레이어·서브모듈이 독립 Xcode project
- **단방향 의존 그래프** — `App → *Feature → Domain(interface) → Core(interface)`, `Shared(interface)` 는 전 레이어 공용
- **모듈별 독립 컴파일/실행/테스트** — Feature 마다 단독 실행용 Example 앱 스킴 보유
- **public API 표면 강제** — 모듈 경계를 넘으려면 `public` 키워드 필수
- **의존성 역전** — 다른 레이어는 구현이 아니라 **Interface** 에만 의존한다

### 모듈 하나의 해부 (`{Layer}{Name}`)

Domain·Core·Shared 모듈은 같은 타겟 세트를 갖는다. 레지스트리(`Modules.swift` 의 `ModulePath`)에 case 를 등록하면 타입드 액세서가 열리고, `Project.swift` 는 팩토리만 호출한다.

| 타겟 | 소스 | 역할 |
|---|---|---|
| `{Layer}{Name}Interface` | `Interface/` | 외부에 노출할 프로토콜·타입·`@Dependency` 키 |
| `{Layer}{Name}Implementation` | `Sources/` | 실제 구현 (자기 Interface 를 import) |
| `{Layer}{Name}Testing` | `Testing/` | 테스트용 Mock/Stub (Interface import) |
| `{Layer}{Name}Tests` | `Tests/` | 단위 테스트 (Implementation + Testing) |

> **Feature 는 예외 — Interface 를 두지 않는다** (D3). `Feature{Name}Implementation`(`Sources/`, Reducer·View) + `Testing` + `Tests` + `Feature{Name}Example`(`Example/`, 독립 실행 앱). 리듀서를 Interface 로 못 가리는 이유 → <doc:FeatureInterface>.

각 레이어 루트의 `Projects/{Layer}/Project.swift` 는 **umbrella 타겟**이다 — 코드 없이 `@_exported import {Layer}{Name}Implementation` 으로 하위 구현을 재노출한다. `import Feature` 한 줄로 모든 Feature 구현에 닿는다. **umbrella 와 `*Implementation` 은 composition root(App)와 Example 앱만 link** 한다.

### 의존성 역전이 지켜지는 방식

레이어를 넘는 의존은 **Interface 전용 액세서**로만 건다. 구현을 모른 채 계약에만 기댄다.

```text
Feature (단일 모듈)   → .domain(interface: .user)      # 비즈니스 계약만
Domain  Implementation → .core(interface: .network)     # 인프라 계약만
어느 레이어든        → .shared(interface: .designSystem) # 공용 계약만
```

구현체(`liveValue` 등)는 누가 넣나? **App 이 레이어 umbrella(`.domain`, `.core` …)를 link 하는 순간** 모든 `*Implementation` 이 그래프에 들어와 `liveValue` 가 활성화된다. Feature·Domain 은 자기 계층 밖 구현을 절대 import 하지 않으므로, 클린 빌드 시 의존 모듈의 **Interface 만** 컴파일하면 된다.

### 두 가지 분리 규칙

이 아키텍처를 지탱하는 절대 규칙 두 개:

1. **Feature → Feature 의존 = 0.** 다른 Feature 로의 전환은 `delegate` 로 신호만 올리고, cross-feature 조립은 ``AppFeature`` (코디네이터)에서만 한다. → <doc:NavigationPatterns>
2. **Domain·Core·Shared 는 Interface/Implementation 분리, Feature 는 단일 모듈.** 다른 레이어는 Interface 에만 의존하고, 구현은 composition root(App)/Example 에서만 link 한다. **Feature 가 Interface 를 안 두는 이유**(TCA 리듀서는 Interface 로 못 가림)는 <doc:FeatureInterface>.

### 모듈 구성

```text
App  (composition root: 레이어 umbrella link + AppFeature 코디네이터)
└── AppFeature  (TabView 코디네이터 + cross-feature 라우팅)
    │
    ├── Feature 레이어 ── FeatureHome (단일 모듈)
    │                     FeatureCommon ──┐ .domain(interface:)
    │                                     ▼
    ├── Domain 레이어 ─── DomainCommon ───┐   (Interface: Client 계약·모델 / Impl: liveValue)
    │                                     │ .core(interface:)
    │                                     ▼
    ├── Core 레이어 ───── CoreCommon        (인프라: 네트워킹 등)
    │
    └── Shared 레이어 ── SharedCommon (+ SharedDesignSystem 이관 대기)   ← 전 레이어가 .shared(interface:) 로 의존
```

전 모듈이 단방향 DAG 로 정렬된다. `Shared/SharedDesignSystem`(이관 대기)은 색상/타이포/spacing 토큰 + 표준 컴포넌트를 보유하고 어느 레이어든 공통으로 의존하게 된다. cross-feature 전환(예: Users 상세 → 프로필 편집)은 모듈 간 화살표로 직접 연결되지 않고 `AppFeature` 를 경유한다 — 그래서 Feature 사이에 의존 선이 없다.

> **현재 상태**: `refactor/#6` 은 TMA 스켈레톤 단계다. 실체가 있는 건 `FeatureHome` 과 레이어별 `*Common` 뿐이고, 나머지(SharedDesignSystem·Users·Profile 등)는 이 골격이 찍어낼 표준형이다.

### Level 4 로 안 간 이유

모노레포 + Bazel 같은 수준은 빌드 캐시·원격 실행 인프라가 따라와야 ROI 가 나온다. 사이드/팀 규모에선 Tuist TMA 가 "모듈 경계 + 의존성 역전 + 빠른 생성 + 단독 실행" 의 이점을 대부분 가져가면서 운영 비용이 낮은 균형점이다.

## Topics

### 함께 보기

- <doc:FeatureInterface>
- <doc:NavigationPatterns>
- <doc:AddingFeature>
