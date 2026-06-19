# Modular Architecture — 이 프로젝트의 위치

Tuist 로 project 자체를 모듈화한 µFeature 아키텍처 안에서 이 프로젝트가 어디에 서 있는지.

## Overview

"모듈러 아키텍처" 라는 용어는 스펙트럼에 가깝다. 한쪽 끝에는 단일 target 에 폴더만 정리하는 일반 사이드 프로젝트가 있고, 반대쪽 끝에는 Tuist · Bazel 같은 빌드 도구로 project 자체를 모듈화한 초대형 앱이 있다.

이 프로젝트는 **Level 3 (Tuist 멀티프로젝트 µFeature)** 에 위치한다 — 화면 도메인마다 독립된 Xcode project(모듈)로 분리하고, 하나의 Workspace 가 `Projects/**` 글롭으로 통합한다.

### 스펙트럼

| 수준 | 설명 | 이 프로젝트 |
|---|---|---|
| 1 | 단일 target + 폴더 정리 | ✗ |
| 2 | 단일 SPM 패키지 + 다중 target | ✗ |
| **3** | **빌드 도구(Tuist)로 project 자체 모듈화 — µFeature** | **여기** |
| 4 | 모노레포 + Bazel 등 (초대형) | ✗ (Lyft · Uber 등) |

### 왜 Tuist µFeature 인가

`Architecture` 앱 타겟은 `ArchitectureApp.swift` 한 파일로 얇게 두고, 실제 코드는 모두 레이어별 독립 모듈로 분리한다. 각 모듈은 자체 `Project.swift` 를 갖고, 루트 `Workspace.swift` 가 `Projects/**` 를 글롭으로 묶는다.

```text
Workspace.swift                  # Projects/** 통합
Tuist/
  ├── Package.swift              # 외부 의존 (ComposableArchitecture)
  └── ProjectDescriptionHelpers/ # Project.feature/.client/.core + 타입드 의존 액세서
Projects/
  ├── App/                       # composition root (App + AppFeature + Documentation)
  ├── Feature/{Home,Users,Profile,Activity}/   # 화면 도메인
  ├── Client/{User,Profile,Activity}Client/    # Repository (Interface + Live)
  └── Shared/{Models,DesignSystemKit}/         # 도메인 모델 + 디자인 토큰
```

modular architecture 의 핵심 조건을 모두 만족한다:

- **모듈 경계 명시** — 각 도메인이 독립 Xcode project
- **단방향 의존 그래프** — `App → AppFeature → *Feature → *ClientInterface → Models`
- **모듈별 독립 컴파일/실행/테스트** — Feature 마다 단독 실행용 Example 앱 스킴 보유
- **public API 표면 강제** — 모듈 경계를 넘으려면 `public` 키워드 필수

`Project.swift` 는 헬퍼 호출 ~5줄이라 target 보일러플레이트가 없고, 모듈 그래프는 `tuist graph` 로 한눈에 본다.

### 두 가지 분리 규칙

이 아키텍처를 지탱하는 절대 규칙 두 개:

1. **Feature → Feature 의존 = 0.** 다른 Feature 로의 전환은 `delegate` 로 신호만 올리고, cross-feature 조립은 ``AppFeature`` (코디네이터)에서만 한다. → <doc:NavigationPatterns>
2. **Feature 는 `*ClientInterface` 만 의존.** `*ClientLive`(실제 구현)는 App 타겟 / Example 앱만 link 해 `liveValue` 를 활성화한다. Client 만 Interface/Live 로 분리하고, Feature 는 단일 모듈(+Testing/Tests/Example)이다.

### 모듈 구성

```text
App
└── AppFeature  (TabView 코디네이터 + cross-feature 라우팅)
    ├── HomeFeature      ────────────────────────── DesignSystemKit
    ├── UsersFeature     ── UserClientInterface ──── Models
    │   └─ Path: UserDetail                          DesignSystemKit
    ├── ActivityFeature  ── ActivityClientInterface ─ Models
    └── ProfileFeature   ── ProfileClientInterface ── Models
                                                      DesignSystemKit
```

전 모듈이 단방향 DAG 로 정렬되어 있다. `DesignSystemKit` 은 색상/타이포/spacing 토큰 + 표준 컴포넌트를 보유하고 모든 Feature 가 공통으로 의존한다. cross-feature 전환(예: Users 상세 → 프로필 편집)은 화살표로 직접 연결되지 않고 `AppFeature` 를 경유한다 — 그래서 `UsersFeature` 와 `ProfileFeature` 사이에 의존 선이 없다.

### Level 4 로 안 간 이유

모노레포 + Bazel 같은 수준은 빌드 캐시·원격 실행 인프라가 따라와야 ROI 가 나온다. 사이드/팀 규모에선 Tuist µFeature 가 "모듈 경계 + 빠른 생성 + 단독 실행" 의 이점을 대부분 가져가면서 운영 비용이 낮은 균형점이다.

## Topics

### 함께 보기

- <doc:FeatureInterface>
- <doc:NavigationPatterns>
- <doc:AddingFeature>
