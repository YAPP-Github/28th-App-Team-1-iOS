# ``Architecture``

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트.

## Overview

이 프로젝트는 다음 네 패턴을 한 앱 안에서 동작하는 형태로 보여주기 위해 만들어졌다.

- **Repository 패턴** — ``UserClient`` / ``ProfileClient`` 처럼 외부 접근은 모두 `@Dependency` 로 주입.
- **Coordinator 패턴** — ``AppFeature/Path-swift.enum`` 한 곳에서 푸시 가능한 화면을 enum 으로 모으고, ``AppFeature`` 가 자식의 delegate 를 받아 스택을 조작.
- **Command 패턴** — 사용자 의도와 시스템 응답을 전부 `Action` 으로 표현. View 는 상태를 직접 바꾸지 않는다.
- **Observer 패턴** — `@ObservableState` + `@Bindable var store` 로 변경 추적. `WithViewStore` 는 사용하지 않는다.

화면은 두 개의 푸시 가능한 자식과 한 개의 루트로 구성된다.

```text
UserList  ──tap row──▶  UserDetail  ──Edit──▶  Profile
                              ▲                     │
                              └─────save delegate ──┘
```

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

### Features

- ``UserListFeature``
- ``UserDetailFeature``
- ``ProfileFeature``

### Domain

- ``User``
- ``Profile``

### Dependencies

- ``UserClient``
- ``ProfileClient``
