# ``AppFeature``

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트의 최상위 모듈.

## Overview

이 프로젝트는 다음 네 패턴을 한 앱 안에서 동작하는 형태로 보여준다.

- **Repository 패턴** — `UserClient` / `ProfileClient` 처럼 외부 접근은 모두 `@Dependency` 로 주입.
- **Coordinator 패턴** — 각 도메인 Feature 가 자체 `Path` enum + `StackState` 를 들고 자기 화면 스택을 조작. ``AppFeature`` 자신은 탭 전환만 담당.
- **Command 패턴** — 사용자 의도와 시스템 응답을 전부 `Action` 으로 표현. View 는 상태를 직접 바꾸지 않는다.
- **Observer 패턴** — `@ObservableState` + `@Bindable var store` 로 변경 추적. `WithViewStore` 는 사용하지 않는다.

### 아키텍처 위치 — Modular Architecture, Level 2 상단

| 수준 | 설명 | 이 프로젝트 |
|---|---|---|
| 1 | 단일 target + 폴더 정리 | ✗ |
| **2** | **단일 SPM 패키지 + 다중 target** | **여기 (8 target)** |
| 3 | 다중 SPM 패키지 (도메인별 독립 패키지) | ✗ (city / isowords 가 이 수준) |
| 4 | Tuist · Bazel 등 빌드 도구로 project 자체 모듈화 | ✗ (Lyft · Uber 등 초대형) |

`Architecture/` 앱 타겟은 `ArchitectureApp.swift` 한 파일로 얇게 두고, 실제 코드는
모두 `ArchitecturePackage` 라는 단일 SPM 패키지 안의 target 단위 모듈로 분리한다.
모듈 경계 명시 · 단방향 의존성 그래프 · 모듈별 독립 컴파일/테스트 · public API 강제
— modular architecture 의 핵심 조건은 모두 만족하면서, Package.swift 한 파일로
전체 그래프가 한눈에 보이는 균형점에 있다.

### 모듈 구성 (Stage 2)

```text
AppFeature  (TabView 코디네이터)
├── HomeFeature       ──────────────── DesignSystemKit
├── UserFeature       ── UserClient ── Models
│   └─ Path: Detail / Profile          DesignSystemKit
├── ActivityFeature   ──────────────── DesignSystemKit
└── ProfileFeature    ── ProfileClient ── Models
                                          DesignSystemKit
```

8 target 모두 단일 ``ArchitecturePackage`` 안에 있으며 단방향 DAG 로 정렬되어 있다.
`DesignSystemKit` 은 색상/타이포/spacing 토큰 + 표준 컴포넌트를 보유하고 모든 Feature 가
공통으로 의존한다 (임시 격리, 추후 확장 여지).

### 탭 구성

| 탭 | Feature | 책임 |
|---|---|---|
| Home | ``HomeFeature`` | 환영 화면 + DSKit 컴포넌트 시연 |
| Users | ``UserFeature`` | 사용자 목록 → 상세 → 프로필 편집 (자체 NavigationStack) |
| Activity | ``ActivityFeature`` | 활동/알림 목록 (빈 상태 포함) |
| Profile | ``ProfileFeature`` | 내 프로필 편집 (재사용) |

### 화면 플로우 (Users 탭 안)

```text
UserList  ──tap row──▶  UserDetail  ──Edit──▶  Profile
                              ▲                     │
                              └─────save delegate ──┘
```

탭 내부 navigation 은 ``UserFeature`` 가 자체 `Path` + `StackState` 로 처리한다.
``AppFeature`` 는 탭 간 전환만 담당하며 탭 내부 화면 스택에는 관여하지 않는다.

## Topics

### 시작하기

- <doc:AddingFeature>
- <doc:NavigationPatterns>

### 협업 규칙

- <doc:CommitConvention>

### Step-by-step tutorial

- <doc:AddingFeatureTutorial>
- <doc:NavigationPatternsTutorial>

### App layer

- ``AppFeature``
- ``AppView``
