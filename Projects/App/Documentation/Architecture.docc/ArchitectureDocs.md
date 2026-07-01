# ``ArchitectureDocs``

@Metadata {
    @DisplayName("Architecture")
}

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트의 통합 문서.

## Overview

이 프로젝트는 다음 패턴을 한 앱 안에서 동작하는 형태로 보여준다.

- **Repository 패턴** — 외부 접근은 모두 `@Dependency` 로 주입하는 Client `struct`. Domain 레이어 모듈이 `Interface`(계약 + `previewValue`/`testValue`) / `Implementation`(`liveValue`)로 분리해 보유한다.
- **Coordinator 패턴** — ``AppFeature`` 가 탭 + cross-feature 라우팅을 중재한다. 도메인 내부 navigation 은 각 Feature 가 자체 `Path` + `StackState` 로 처리하고, Feature 간 전환은 `delegate` 로 ``AppFeature`` 에 위임한다 (Feature→Feature 의존 0).
- **Command 패턴** — 사용자 의도와 시스템 응답을 전부 `Action` 으로 표현. View 는 상태를 직접 바꾸지 않는다.
- **Observer 패턴** — `@ObservableState` + `@Bindable var store` 로 변경 추적. `WithViewStore` 는 사용하지 않는다.

### 아키텍처

modular architecture 스펙트럼 안에서 이 프로젝트는 **Level 3+ (Tuist 멀티프로젝트 TMA)** — `Core / Domain / Feature / Shared` 레이어마다 독립 Xcode project 로 분리하고, Domain·Core·Shared 는 각 모듈을 다시 `Interface` / `Implementation` 으로 쪼갠다 (Feature 는 단일 모듈). 하나의 Workspace 가 `Projects/**` 로 통합한다. 자세한 레이어·모듈 그래프·의존성 역전은 <doc:ModularArchitecture>, TCA 와 모듈 경계가 만나는 지점(리듀서는 왜 Interface 로 못 가나)은 <doc:FeatureInterface> 참조.

### 화면 도메인

> 현재 `refactor/#6` 은 TMA 스켈레톤 단계다. `FeatureHome` 과 레이어별 `*Common` 만 실체가 있고, 아래 나머지 도메인은 이 골격이 찍어낼 표준형이다.

| 도메인 | Feature | 책임 | 상태 |
|---|---|---|---|
| Home | ``HomeFeature`` | 홈 화면 (외부 IO 없는 Feature 예시) | ✅ 구현 |
| Users | `UsersFeature` | 목록 → 상세 (자체 NavigationStack). 편집은 앱 레벨 sheet 로 위임 | 이관 대기 |
| Profile | `ProfileFeature` | 내 프로필 편집 (재사용) | 이관 대기 |

### 화면 플로우 (Users → 프로필 편집)

탭 내부 navigation(목록→상세)은 `UsersFeature` 가 자체 `Path` + `StackState` 로 처리한다. 하지만 프로필 편집은 **다른 Feature(`ProfileFeature`)** 라 `UsersFeature` 가 직접 열지 않고 `delegate` 로 ``AppFeature`` 에 올린다. ``AppFeature`` 가 앱 레벨 sheet 로 `ProfileFeature` 를 제시하고 저장 결과를 다시 통보한다 — Feature 간 의존 0 을 지키는 cross-feature 라우팅. 상세 → <doc:NavigationPatterns>.

## Topics

### 아키텍처

- <doc:ModularArchitecture>
- <doc:FeatureInterface>

### 시작하기

- <doc:AddingFeature>
- <doc:NavigationPatterns>

### 빌드 · 환경

- <doc:Environments>

### 협업 규칙

- <doc:CommitConvention>

### App layer

- ``AppFeature``
- ``AppView``
