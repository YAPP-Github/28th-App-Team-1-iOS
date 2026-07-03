# Architecture — 시스템 설계 & 핵심 결정

SwiftUI + TCA · Tuist TMA(The Modular Architecture)의 시스템 총론. 이 문서는 **전체 그림과 "왜 이렇게 했는가"** 만 담는다. 작업 규칙은 `CLAUDE.md`, 심볼/개념 레퍼런스는 `Architecture.docc` 를 본다.

## 레이어 & 의존 방향
앱은 한 방향으로만 의존한다. 다른 레이어는 구현이 아니라 **Interface(계약)** 에 의존하고, 구현(`*Implementation`)은 composition root(App)/Example 만 link 한다.

```
App → *Feature → Domain(interface) → Core(interface)
       (화면)      (모델·Repository)     (인프라)
전 레이어 → Shared(interface)  (DesignSystem 등)
```

- **App**: composition root. 레이어 umbrella(`.core`/`.domain`/`.feature`/`.shared`)를 link 해 모든 `*Implementation` + `liveValue` 활성화 (link 만으론 부족 — `-all_load` 가 필요하다 → D4).
- **Feature**: 화면 도메인. **Interface 없는 단일 모듈** — 구현 타겟(`Feature{Name}Implementation`) 하나 + Testing/Tests/Example. Reducer·View 는 `Sources/`. → [[app#Cross-feature Routing]]
- **Domain**: 도메인 모델 + Repository(Client). `Interface`(계약 + `previewValue`/`testValue`) / `Implementation`(`liveValue`).
- **Core**: 인프라(네트워킹 등). `Interface` / `Implementation`.
- **Shared**: 디자인 토큰 등 공용. 어느 레이어든 `.shared(interface:)` 로 의존.
- 각 레이어 루트 `Project.swift` 는 umbrella — `Sources/Source.swift` 의 `@_exported import` 로 하위 구현을 재노출한다.

## 핵심 결정 (Trade-off 기록)
이 아키텍처를 규정하는 네 가지 결정과 각각의 비용.

### D1. Feature → Feature 의존 = 0 (delegate-only)
다른 Feature 로의 전환은 `delegate` 신호만 올리고, 조립은 **AppFeature 에서만** 한다.
- **이유**: 결합 0, 컴파일 격리, 피쳐 단독(Example) 실행.
- **비용**: cross-feature 의존이 **import 에 안 보인다** → 변경 영향 추적이 어려움. → 이 약점을 `@lat depends-on` 라벨로 메운다. (lat 도입 제1 명분)

### D2. 단일 코디네이터 (AppFeature)
피쳐별 sub-coordinator 대신 AppFeature 하나가 모든 cross-feature 를 중재.
- **이유**: 2인 / 모듈 ~10개 규모에선 분산 코디네이터의 빌드격리 이득이 거품.
- **재검토 임계점**: 피쳐 15개↑ 또는 다단계 cross-feature 네비가 일상화되면 sub-coordinator 로 전환 검토.

### D3. Domain·Core·Shared 는 Interface/Implementation, Feature 는 단일 모듈
Domain·Core·Shared 는 `Interface`(계약) / `Implementation`(구현)으로 쪼개고 다른 레이어는 Interface 에만 의존한다. **Feature 는 Interface 를 두지 않는다** (구현 타겟 하나 + Testing/Tests/Example).
- **이유(리듀서)**: `@Reducer` 매크로 + `some` 정적 합성이 구체 타입을 강제 → 리듀서는 Interface 로 못 가린다. Feature Interface 는 State 를 통째로 public 노출시켜 캡슐화 이득이 절반인데 보일러플레이트는 4겹. 상세 → DocC 개념 아티클 [FeatureInterface](../Projects/App/Documentation/Architecture.docc/Architecture/FeatureInterface.md)
- **이력**: `experiment/feature-interface-tma` 브랜치로 Feature Interface 비용을 재확인한 뒤 폐기했다 (`refactor: Feature Interface 제거`).

### D4. liveValue 활성화와 all_load
umbrella link 만으로는 liveValue 가 켜지지 않는다. 정적 아카이브에서 링커는 참조된 오브젝트 파일만 싣는데, Domain 등의 Implementation 은 extension(DependencyKey)뿐이라 참조가 없어 통째로 탈락한다. 그래서 composition root(App·Example) 타겟에 `-all_load` 를 건다.
- **적용 위치**: `Target+Templates.swift` 의 `.app(factory:)` / `feature(example:)` 팩토리 — 새 모듈 추가 시 아무것도 기억할 필요 없다(레지스트리 자동화 철학 유지).
- **비용**: 미참조 코드까지 실려 바이너리 소폭 증가. 서드파티 **정적** 라이브러리 도입 시 중복 심볼이 링크 에러로 드러날 수 있다 — 침묵 폴백보다 낫고, 그때는 `ModulePath` 순회 `-force_load` 로 좁히는 마이그레이션 경로가 있다.
- **검증법**: 심볼 검사는 `App.app/App`(debug 에선 123KB 스텁)이 아니라 **`App.debug.dylib`** 을 `nm` 으로 본다. 플래그 없이는 conformance 0개 — 빌드·테스트는 전부 성공하고 런타임에만 testValue 로 침묵 폴백하는 최악의 증상이었다.

## 디자인 시스템
`Shared/SharedDesignSystem`(이관 대기) 토큰 우선: `Color.dsPrimary` / `Font.dsBody` / `CGFloat.dsL` / `PrimaryButton`. 하드코딩 지양.
