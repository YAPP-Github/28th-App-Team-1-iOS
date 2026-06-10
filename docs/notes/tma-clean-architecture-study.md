# Keepiluv-iOS 아키텍처 학습 노트

> [!NOTE] 외부 스터디 노트
> 이 문서는 **다른 프로젝트(Keepiluv-iOS)** 를 분석한 비교 학습 메모입니다.
> 본 Architecture 리포의 구조를 설명하지 않습니다 — 여기엔 `Projects/Core`·`Projects/Domain`·`AGENTS.md` 가 없습니다.
> 이 프로젝트의 아키텍처는 [README](../../README.md) · DocC `ModularArchitecture` · [`lat.md/architecture.md`](../../lat.md/architecture.md) 를 보세요.
> TMA=MFA=µFeatures 계보, Umbrella 패턴, Clean 지향 같은 **개념 참고용**으로만 둡니다.

> 작성일: 2026-06-02
> 범위: 모듈 구조(Umbrella) · 타깃 패턴 비교 · TMA + Clean Architecture 정체성
> 근거: 다른 리포의 실제 코드(`Projects/`, `Tuist/ProjectDescriptionHelpers/`)와 `docs/Architecture/Overview.md`

---

## 0. TL;DR (한눈에)

- **모듈 패키징 = Tuist의 The Modular Architecture(TMA)** = 프로젝트 문서가 부르는 **MFA(Micro Feature Architecture)**. 같은 패턴의 다른 이름.
- **레이어/의존성 = Clean Architecture 지향** (App→Feature→Domain→Core/Shared, 안쪽으로 의존).
- 단, Domain은 교과서적 `UseCase/Repository`가 아니라 **TCA struct Client**로 실용화 → "Client 기반 Clean 지향".
- 두 개념은 **직교(orthogonal)** 한 축이라 함께 쓰는 게 자연스럽다.

```
[모듈 패키징 축]  TMA / MFA      → 모듈을 어떤 타깃으로 쪼갤지 (Interface/Impl/Testing/Tests/Example)
[의존성 레이어 축] Clean Arch.    → 레이어 의미와 의존 방향 (App→Feature→Domain→Core/Shared)
```

---

## 1. 모듈 구조 개요

`Projects/` 최상위 5개 그룹:

```
Projects/
├── App/        # @main 진입점, Feature 조립
├── Feature/    # UI + 화면 비즈니스 로직 (TCA Reducer/View)
├── Domain/     # 도메인 모델 + 비즈니스 규칙 (Feature 비의존)
├── Core/       # 네트워크·저장소·로깅 등 인프라
└── Shared/     # 디자인 시스템·유틸·서드파티 래핑
```

각 그룹 폴더 안에는 **(a) 개별 기능 모듈 폴더**(각자 `Project.swift` 보유)와 **(b) 그룹 루트 umbrella**(`Project.swift` + `Sources/`)가 함께 존재한다.

의존성 방향(레이어 규칙):

```
App ─▶ Feature ─▶ Domain ─▶ Core ─▶ Shared
                  (Domain은 Feature를 모름 = inward dependency)
```

---

## 2. Umbrella(우산) 모듈 패턴

### 개념
"커다란 Core/Domain/Feature"는 실제 코드가 거의 없는 **Umbrella(=Aggregate / Facade) 모듈**.
하위 모듈들을 의존성으로 끌어안고 `@_exported import`로 **다시 노출(re-export)** 해서, 소비자가 `import Core` 한 줄로 여러 모듈을 쓰게 하는 **편의 진입점**.

### 그룹별 성숙도 (★ 중요: 셋이 다름)

| 그룹 | 의존성 집계 | re-export(facade) 실제 동작 |
|---|---|---|
| **Core** | 모든 `.core(implements:)` | ✅ `@_exported import` (Logging/Network/Storage) |
| **Domain** | 모든 `.domain(implements:)` | ❌ `Sources/Source.swift`가 `"Remove Or Edit"` **빈 플레이스홀더** |
| **Feature** | 모든 interface+implements + 일부 Domain | ✅ Auth/MainTab/Onboarding을 `typealias`/`import`로 노출 |

근거:
- `Projects/Core/Sources/Core.swift` → `@_exported import CoreLogging / CoreNetwork / CoreStorage ...`
- `Projects/Domain/Sources/Source.swift` → 아직 빈 껍데기 (그래프 집계용)
- `Projects/Feature/Sources/Source.swift` → "App은 Feature만 import하면 하위 Feature 타입 사용 가능" 주석 + Auth/MainTab/Onboarding re-export

### 인사이트
- Feature umbrella가 노출하는 **Auth/MainTab/Onboarding**은 `AGENTS.md`의 **예외 Feature(App/coordinator가 직접 조립)** 와 정확히 일치 → "App이 직접 써야 할 것만 우산에 올린다"는 절제.
- Core도 모든 하위를 의존하지만 re-export는 범용 3종만 → 우산 남용 방지.
- ⚠️ 트레이드오프: umbrella를 import하면 그 안 전부에 의존하게 되어 "필요한 Interface만 의존" 원칙과 긴장 관계. 그래서 의도적으로 노출 범위를 제한.

---

## 3. 타깃 패턴 비교 (Core / Domain / Feature)

### 공통 4-타깃 골격
세 그룹의 헬퍼(`Target+Core.swift`, `Target+Domain.swift`, `Target+Feature.swift`)는 **이름만 다르고 구조가 동일**.

| 팩토리 | 생성 타깃 이름 | sources |
|---|---|---|
| `.X(config:)` | `Core` / `Domain` / `Feature` (umbrella root) | `.sources` |
| `.X(interface:)` | `{Module}Interface` | `.interface` |
| `.X(implements:)` | `{Module}` | `.sources` |
| `.X(testing:)` | `{Module}Testing` (Mock 지원) | `.testing` |
| `.X(tests:)` | `{Module}Tests` (`.unitTests`) | `.tests` |

### Feature만 추가로 갖는 2개 타깃 ⭐

| 팩토리 | 생성 타깃 | product |
|---|---|---|
| `.feature(example:)` | `{Module}Example` | `.app` (독립 실행 예제 앱) |
| `.feature(exampleUITests:)` | `{Module}ExampleUITests` | `.uiTests` |

→ **Feature는 실질 6-타깃.** 이유: 각 Feature를 앱 전체 빌드 없이 **자기 예제 앱으로 독립 실행/테스트** = MFA/TMA의 핵심 동기. Core/Domain은 UI 진입점이 없어 Example 불필요.

### 실제 `Project.swift`가 찍어내는 타깃 수

| 모듈 | 예시 | 생성 타깃 |
|---|---|---|
| Core | `Network` (`Projects/Core/Network/Project.swift`) | interface · implements · testing · tests (**4**) |
| Domain | `Goal` (`Projects/Domain/Goal/Project.swift`) | interface · implements · testing · tests (**4**) |
| Feature | `Home` (`Projects/Feature/Home/Project.swift`) | interface · implements · testing · tests · example · exampleUITests (**6**) |

---

## 4. TMA(=MFA) + Clean Architecture 정체성

### 4-1. 모듈 패키징 = TMA = MFA
- 관찰된 타깃 분류(Interface/Impl/Testing/Tests/Example)는 **Tuist의 The Modular Architecture(TMA) 표준과 1:1 일치**.
- 역사: Tuist가 처음엔 **µFeatures(micro features)** → 후에 **TMA**로 개명. 즉 **µFeatures = MFA = TMA** 동일 계보.
- 프로젝트 문서(`AGENTS.md`)는 "MFA"로 표기하지만 **구현체는 TMA 그대로**. 둘 다 맞는 말.

### 4-2. 레이어 = Clean Architecture "지향"
잘 지키는 부분:
- 레이어 분리 App→Feature→Domain→Core→Shared, **Domain은 Feature 비의존**(inward).
- 모든 의존이 `implements`가 아니라 **`interface`** 를 향함 → 의존성 역전(DIP).

교과서적 Clean과 다른 부분(정직하게):
- Domain에 **Entity는 있으나** `UseCase`/`Repository`/`Interactor` 타입은 **없음**.
- 그 역할을 **TCA struct Client**가 통합 수행.
  - `Projects/Domain/Goal/Interface/Sources/GoalClient.swift` (계약)
  - `Projects/Domain/Goal/Sources/GoalClient+Live.swift` (구현)
  - `.../Interface/Sources/Entity/Goal.swift`, `GoalDetail.swift` (Entity)
  - `.../Interface/Sources/DTO/*`, `Endpoint/*`
- → **"Client 기반 Clean 지향 + TCA"** 가 가장 정확한 표현.

---

## 5. 두 축이 맞물리는 지점 (핵심)

TMA의 **Interface/Implementation 분리**가 Clean Architecture의 **DIP를 컴파일러로 강제**한다:

```
FeatureHome(impl) ──depends on──▶ DomainGoalInterface ◀──implements── DomainGoal(impl)
                                  (계약만 컴파일 의존)        (런타임 주입)
```

소비자는 `DomainGoalInterface`(계약)만 알고 실제 구현(`DomainGoal`)은 모른다 → "안쪽을 향하는 의존" 규칙이 **모듈 경계로 강제**됨. 즉 TMA가 Clean을 "지킬 수밖에 없게" 만드는 골격.

---

## 6. 용어 정리

| 용어 | 의미 | 이 프로젝트에서 |
|---|---|---|
| TMA (The Modular Architecture) | Tuist 공식 모듈화 패턴 | 실제 타깃 구성이 이것 |
| MFA / µFeatures | TMA의 옛 이름(동일) | 문서 표기상 명칭 |
| Umbrella / Facade 모듈 | 하위 모듈 re-export 진입점 | Core(활성)/Feature(App용)/Domain(빈 껍데기) |
| Interface 타깃 | 공개 계약 | DIP 강제의 핵심 |
| Clean Architecture | 레이어+의존성 규칙 | 지향. UseCase/Repository는 Client로 대체 |

---

