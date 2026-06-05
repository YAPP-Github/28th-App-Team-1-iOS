# ``ArchitectureDocs``

@Metadata {
    @DisplayName("Architecture")
}

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트의 통합 문서.

## Overview

이 프로젝트는 다음 네 패턴을 한 앱 안에서 동작하는 형태로 보여준다.

- **Repository 패턴** — `UserClient` / `ProfileClient` 처럼 외부 접근은 모두 `@Dependency` 로 주입.
- **Coordinator 패턴** — 각 도메인 Feature 가 자체 `Path` enum + `StackState` 를 들고 자기 화면 스택을 조작. ``AppFeature`` 자신은 탭 전환만 담당.
- **Command 패턴** — 사용자 의도와 시스템 응답을 전부 `Action` 으로 표현. View 는 상태를 직접 바꾸지 않는다.
- **Observer 패턴** — `@ObservableState` + `@Bindable var store` 로 변경 추적. `WithViewStore` 는 사용하지 않는다.

### 아키텍처

모듈러 아키텍처 스펙트럼 안에서 이 프로젝트는 **Level 2 의 상단** — 단일 SPM 패키지 + 8 target 으로 구성된다. 자세한 위치와 모듈 그래프는 <doc:ModularArchitecture> 참조.

### 탭 구성

| 탭 | Feature | 책임 |
|---|---|---|
| Home | ``HomeFeature`` | 환영 화면 + DSKit 컴포넌트 시연 |
| Users | ``UsersFeature`` | 사용자 목록 → 상세 → 프로필 편집 (자체 NavigationStack) |
| Activity | ``ActivityFeature`` | 활동/알림 목록 (빈 상태 포함) |
| Profile | ``ProfileFeature`` | 내 프로필 편집 (재사용) |

### 화면 플로우 (Users 탭 안)

```text
UserList  ──tap row──▶  UserDetail  ──Edit──▶  Profile
                              ▲                     │
                              └─────save delegate ──┘
```

탭 내부 navigation 은 ``UsersFeature`` 가 자체 `Path` + `StackState` 로 처리한다. ``AppFeature`` 는 탭 간 전환만 담당하며 탭 내부 화면 스택에는 관여하지 않는다.

## Topics

### 아키텍처

- <doc:ModularArchitecture>

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
