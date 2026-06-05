# Modular Architecture — 이 프로젝트의 위치

다중 SPM target 으로 분리된 모듈러 아키텍처 안에서 이 프로젝트가 어디에 서 있는지.

## Overview

"모듈러 아키텍처" 라는 용어는 스펙트럼에 가깝다. 한쪽 끝에는 단일 target 에 폴더만 정리하는 일반 사이드 프로젝트가 있고, 반대쪽 끝에는 Tuist · Bazel 같은 빌드 도구로 project 자체를 모듈화한 초대형 앱이 있다.

이 프로젝트는 **Level 2 의 상단** 에 위치한다 — 단일 SPM 패키지 안에 8 개 target 으로 분리한 형태.

### 스펙트럼

| 수준 | 설명 | 이 프로젝트 |
|---|---|---|
| 1 | 단일 target + 폴더 정리 | ✗ |
| **2** | **단일 SPM 패키지 + 다중 target** | **여기 (8 target)** |
| 3 | 다중 SPM 패키지 (도메인별 독립 패키지) | ✗ (city / isowords 가 이 수준) |
| 4 | Tuist · Bazel 등 빌드 도구로 project 자체 모듈화 | ✗ (Lyft · Uber 등 초대형) |

### 왜 Level 2 인가

`Architecture/` 앱 타겟은 `ArchitectureApp.swift` 한 파일로 얇게 두고, 실제 코드는 모두 `ArchitecturePackage` 라는 단일 SPM 패키지 안의 target 단위 모듈로 분리한다.

modular architecture 의 핵심 조건은 모두 만족한다:

- **모듈 경계 명시** — 8 개 target 각각이 독립된 단위
- **단방향 의존성 그래프** — `AppFeature → UserFeature → UserClient → Models`
- **모듈별 독립 컴파일/테스트** — target 단위로 build / test 가능
- **public API 표면 강제** — target 경계를 넘으려면 `public` 키워드 필수

그러면서도 Package.swift 한 파일로 전체 그래프가 한눈에 보이는 균형점에 있다.

### Level 3 으로 안 간 이유

Level 3 (도메인별 독립 SPM 패키지) 으로 가면 각 모듈이 자체 Package.swift · 자체 platform target · 자체 Swift tools version 을 가질 수 있어 더 엄격해진다. 하지만:

- 패키지가 늘어날 때마다 Package.swift 관리 비용이 증가
- 모듈 간 의존을 표현하려면 `.package(path: "../OtherModule")` 같은 path 참조가 늘어남
- 사이드 프로젝트 규모에선 ROI 가 낮음

도메인 응집과 재사용성이 정말 필요해질 때 (다른 앱에 모듈 가져가야 할 때, 패키지별로 다른 platform 을 노려야 할 때) 가 Level 3 으로 갈 신호다.

### 모듈 구성

```text
AppFeature  (TabView 코디네이터)
├── HomeFeature       ──────────────── DesignSystemKit
├── UserFeature       ── UserClient ── Models
│   └─ Path: Detail / Profile          DesignSystemKit
├── ActivityFeature   ──────────────── DesignSystemKit
└── ProfileFeature    ── ProfileClient ── Models
                                          DesignSystemKit
```

8 target 모두 단일 ``ArchitecturePackage`` 안에 있으며 단방향 DAG 로 정렬되어 있다. `DesignSystemKit` 은 색상/타이포/spacing 토큰 + 표준 컴포넌트를 보유하고 모든 Feature 가 공통으로 의존한다.

## Topics

### 함께 보기

- <doc:NavigationPatterns>
- <doc:AddingFeature>
