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
이 아키텍처를 규정하는 다섯 가지 결정과 각각의 비용.

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
- **SPM 산출물 타입은 1차 모듈과 맞춘다**(`Tuist/Package.swift`) — 정적 산출물은 자기를 link 한 이미지마다 사본이 박힌다. 1차 모듈이 동적인 로컬 generate 는 공유 패키지(TCA·Dependencies·카카오)를 `.framework` 로 올리고, 정적 릴리스(`TUIST_PRODUCT_TYPE=static-library`)는 오버라이드를 걷어 앱 바이너리 한 벌로 합친다. 어긋나면 `objc: Class … is implemented in both …` 경고와 전역 상태(DependencyValues 등) 분열이 난다.

### D5. Reducer Action 3분류
Action enum 을 `view(View)` / `inner(Inner)` / `delegate(Delegate)` 로 나눈다. `view` 는 View 의 `send(...)` 로만, `inner` 는 리듀서만 방출하고, 부모는 자식의 `delegate` 만 매칭한다.
- **이유**: 경계 강제 — View 가 내부 액션을 쏘거나 부모가 자식 내부 액션을 가로채는 결합을 차단(D1 의 액션 레벨 버전). 커뮤니티 표준(Zabłocki action boundaries + TCA `@ViewAction` 매크로)과 일치. 표준형은 Feature 스캐폴드 템플릿(`Tuist/Templates/Feature/FeatureReducer.stencil`)이 찍어낸다.
- **비용**: 테스트가 `store.send(.view(.onAppear))` 로 장황해진다. switch 총량은 줄지 않는다 — 길어지면 카테고리별 private `reduceView`/`reduceInner` 로 나눈다.
- **비채택**: 별도 `async` 카테고리 — "async 트리거"와 "async 응답" 중 무엇을 담는지 경계가 애매해 바이크셰딩을 부른다. 응답은 `inner` 로 흡수. binding 은 `View: BindableAction` + `BindingReducer(action: \.view)` 로 view 아래 중첩.

## 디자인 시스템
`Shared/SharedDesignSystem` 토큰 우선, 하드코딩 지양. 타이포그래피는 `DSTypography`(25종, Pretendard 4웨이트) + `.dsTypography(_:)` — Figma «[0722 H/O] HILIT_Text_Guide» 1:1. 색·spacing·outline 토큰 구현 완료, 공용 컴포넌트 카탈로그는 `.claude/design/component.md` 참조(열거하지 않음 — 자주 늘어난다).

- **토큰 위치**: 전부 Interface — 상수 계약이라 live/test 분리가 없다. 폰트 otf 도 Interface 리소스로 싣고, 등록은 Tuist 생성 폰트 접근자가 첫 사용 시 알아서 한다 — App 배선·수동 부트스트랩 불필요(`Pretendard.registerAll()` 은 미사용 웨이트까지 필요한 검증용).
- **행간 구현**: SwiftUI 에 line-height 가 없어 `lineSpacing + 상하 패딩` 보정으로 Figma px 값을 재현. Dynamic Type 은 미반영(고정 사이즈) — 도입 결정 시 `relativeTo:` 전환.
- **스펙 대조**: 토큰 ↔ Figma 스타일명 1:1 은 `DSTypographyTests` 가 고정한다. 상세 토큰 표 → `.claude/design/typography.md` (인덱스: `.claude/design.md`). spacing 상세 → `.claude/design/spacing.md`.
- **색상**: Figma «Hilit_Color_Guide»(node 366-173) 확정 팔레트 23색 — 패밀리 enum(`Color.HilitGreen.g500`·`Color.GrayScale.g600`…). 에셋명은 HEX(`Color636777`)라 의미가 없어 enum 이 의미를 입힌다. 카탈로그도 같은 6그룹 폴더(namespace 미사용), 로드는 Tuist 생성 접근자, 토큰↔HEX 대조는 `ColorPaletteTests`. 상세 표 → `.claude/design/color.md`.
- **이미지**: Figma «icon» 시트(node 1941-7000) — 패밀리 enum(`Image.Cancel.white24`), 일러스트는 `Image.Img`. 색변형이 전부 별도 에셋이라 **틴트하지 않는다**. 크기별 별도 에셋 유지(Figma 가 크기마다 다시 그림 — optical sizing). 명명·마이그레이션 규칙 → `.claude/design/image.md`.
- **바텀시트는 시스템 `.sheet` 를 안 쓴다**(2026-08-07, 이슈 #72): iOS 26 이 부분 높이 시트를 화면 가장자리에서 띄워 그려(양옆·아래 여백 + 큰 라운드) 시안의 «폭 꽉·모서리 0» 판이 다른 물건이 됐고 디자인이 반려했다. `.hilitDetentSheet`(시스템 래퍼)를 지우고 `.hilitBottomSheet` 하나가 딤·자리·드래그·그래버까지 갖는 오버레이가 됐다 — 자리는 화면 높이 대비 비율 배열, 착지·닫기 판정은 `HilitBottomSheetMotion`. **키보드가 뜨는 시트도 같은 이유로 진작 오버레이였다**([[feedback#G4 게스트 평가]] 닉네임 패널) — 이제 근거가 하나로 모였다. 시트 룩이 OS 몫이 아니게 되면서 «판은 호출부가 그린다» 던 옛 계약도 접었다(호출부는 판 색·본문만).
