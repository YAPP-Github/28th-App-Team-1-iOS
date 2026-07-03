# Architecture — Claude 작업 가이드

SwiftUI + TCA 레퍼런스 사이드 프로젝트. **Tuist 기반 TMA(The Modular Architecture)** — 앱을 `Core / Domain / Feature / Shared` 4 레이어로 나누고, 각 모듈을 `Interface`(계약) / `Implementation`(구현)으로 분리한다. Feature 간 결합은 코디네이터(`AppFeature`)가 중재한다.

> **현재 상태**: `refactor/#6` 은 TMA **스켈레톤** 단계다. 레이어별 `*Common` 골격과 `FeatureHome` 만 실체가 있고, 나머지(SharedDesignSystem·Users·Profile 등)는 이관 대기다. 아래 규칙은 이 골격이 **찍어내는 모듈의 표준형**을 설명한다.

## 프로젝트 구조

```
Workspace.swift                              ← Projects/** glob 통합
Plugins/DependencyPlugin/ProjectDescriptionHelpers/
    Modules.swift                            ← 모듈 레지스트리(ModulePath enum) — 새 모듈은 여기 먼저 등록
    Path+Modules.swift · TargetDependency+Modules.swift  ← 타입드 경로·의존 액세서
Tuist/
├── Package.swift                            ← 외부 의존 (ComposableArchitecture)
├── ProjectDescriptionHelpers/               ← Project.makeModule + Target 팩토리(.app/.core/.domain/.feature/.shared)
└── Templates/{Core,Domain,Feature,Shared}/  ← tuist scaffold 용 레이어별 스텐실
Projects/
├── App/                                       composition root
│   ├── Sources/                                 App @main + AppFeature(탭 코디네이터) + AppView
│   ├── Config/{Dev,Prod,QA}.xcconfig            환경 분리
│   └── Documentation/                           ArchitectureDocs 타겟 — 전역 DocC 카탈로그 (코드 없음)
├── Core/    {CoreCommon, …}                     인프라(네트워킹 등). Interface/Implementation
├── Domain/  {DomainCommon, …}                    도메인 모델 + Repository(Client). Interface/Implementation
├── Feature/ {FeatureCommon, FeatureHome, …}      화면 도메인. **단일 모듈** (Sources/Testing/Tests/Example, Interface 없음)
└── Shared/  {SharedCommon, SharedDesignSystem…} 디자인 토큰 등 공용. Interface/Implementation
```

각 레이어 루트의 `Projects/{Layer}/Project.swift` 는 **umbrella 타겟**(`@_exported import` 로 하위 Implementation 재노출) — **App / Example 앱만** link 한다.

의존 방향: `App → *Feature(Impl) → Domain(interface) → Core(interface)`. `Shared(interface)` 는 전 레이어가 의존 가능. **Implementation·umbrella 는 App/Example 만** link 한다.

## 핵심 아키텍처 규칙 (절대 위반 금지)

- **Feature → Feature 의존 0.** 다른 Feature 로의 전환은 직접 하지 않고 `delegate` 로 신호만 올린다. cross-feature 조립은 **`AppFeature`(코디네이터)에서만**. (예: `UsersFeature` 가 `.delegate(.editProfile(id))` 방출 → AppFeature 가 앱 레벨 sheet 로 `ProfileFeature` 제시 → 저장 결과를 `.users(.profileUpdated)` 로 통보)
- **Domain·Core·Shared 는 Interface/Implementation 분리, Feature 는 단일 모듈.** 다른 레이어 모듈은 **Interface 만** 의존한다 — `.domain(interface: .xxx)`, `.core(interface: .xxx)`, `.shared(interface: .xxx)`. 구현(`*Implementation`)과 레이어 umbrella 는 **App/Example 만** link 해 `liveValue` 를 활성화한다. Feature·Domain 은 다른 모듈의 Implementation 을 절대 import 하지 않는다.
- **Feature 는 Interface 를 두지 않는다 (D3 = Feature Interface 폐기).** Reducer/State/View 는 구현 타겟(`Feature{Name}Implementation`, `Sources/`) 하나에 다 있다 — `@Reducer` 매크로 + `some` 정적 합성이 구체 타입을 강제해 리듀서는 Interface 로 못 가리기 때문(→ DocC `FeatureInterface`). Feature 로의 진입·전환에 필요한 신호는 `delegate` 로 올려 AppFeature 가 조립한다.
- **Repository(외부 IO)는 Domain 레이어 모듈.** `Interface` 에 Client `struct` + `DependencyValues` 키 + `previewValue`/`testValue`, `Implementation` 에 `liveValue`. (별도 Client 레이어는 없다 — Domain 이 흡수)

## 패턴 — 순수 TCA

- 화면 1개당 파일 2개: `XxxFeature.swift` (Reducer) + `XxxView.swift` (View). 둘 다 `Implementation/Sources/`.
- Reducer 가 비즈니스 로직 + 도메인 내부 navigation 처리. 도메인 안 navigation 은 그 Feature 자체 `Path` + `StackState` 로.
- 외부 IO 는 항상 `@Dependency` 로 주입. Client 는 Domain 모듈(Interface + Implementation)
- `@ObservableState` + `@Bindable var store` 표준. `WithViewStore` 금지

## 새 모듈 추가 흐름

상세·체크리스트는 **`docs/adding-module.md`** 단일 소스. 요약:

1. **레지스트리 등록** — `Plugins/DependencyPlugin/ProjectDescriptionHelpers/Modules.swift` 의 `ModulePath.{Core|Domain|Feature|Shared}` 에 `case` 추가 (rawValue = 디렉토리 접미사, 예 `case interview = "Interview"` → `Projects/Feature/FeatureInterview/`). → umbrella `Project.swift` 의존이 여기서 자동 생성된다.
2. **모듈 Project.swift** — `Projects/{Layer}/{Layer}{Name}/Project.swift` 작성. 레이어 팩토리 호출 ~10줄. Domain/Core/Shared 는 `.xxx(interface:)` + `.xxx(implements:)` + `.xxx(testing:/tests:)`. **Feature 는 interface 없이** `.feature(implements:factory:)` + `.feature(testing:/tests:/example:)`.
3. **소스 디렉토리** — Domain/Core/Shared 는 `Interface/`·`Sources/`·`Testing/`·`Tests/`, Feature 는 `Sources/`·`Testing/`·`Tests/`·`Example/` (Interface 없음) 에 Swift 파일 ≥ 1 (Tuist 는 글롭으로 타겟 생성)
4. **umbrella 재노출 (Source.swift 만 수동)** — umbrella `Projects/{Layer}/Project.swift` 의 dependencies 는 `ModulePath.{Layer}.allCases` 를 순회해 **자동 생성**되므로 손댈 필요 없다(1번 case 등록으로 충분). `Projects/{Layer}/Sources/Source.swift` 에 `@_exported import {Layer}{Name}Implementation` 한 줄만 추가하면 App 이 `import {Layer}` 로 재노출받는다.
5. cross-feature 전환이면 그 Feature 에 `delegate` case 추가 → `AppFeature` 가 수신/조립. 새 탭이면 `AppFeature.State`/`Tab`/`AppView` 에 추가
6. `tuist generate`

각 모듈 `Project.swift` 는 팩토리 호출뿐. target 을 직접 나열하지 않는다.

## 빌드 / 실행

- 프로젝트 생성: `tuist install && tuist generate` (`.xcworkspace`/`.xcodeproj` 는 생성물 — 커밋 안 함)
- 빌드: `xcodebuild -workspace App.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build`
- 테스트: `make test scheme=FeatureHome` 권장 (사용 가능한 시뮬레이터 UDID 로 해석 — 기기 이름이 여러 OS 런타임에 중복돼도 안전). 직접 xcodebuild 쓸 때 `name=iPhone 16` 이 중복으로 "Unable to find a device" 나면 `,OS=26.0` 또는 `id=<UDID>` 로 지정
- Feature 단독 실행: `Feature{Name}` 스킴 ⌘R — Example 앱이 그 스킴의 실행 타겟 (예: `FeatureHome` 스킴 → `FeatureHomeExample.app`. `FeatureHomeExample` 이라는 스킴은 없다)
- **umbrella 의존을 고치면 반드시 `tuist generate` 재실행** — 캐시된 그래프로 빌드하면 새 의존이 누락된 채 "거짓 성공" 이 난다.
- DocC: Xcode 의 Product → Build Documentation (`ArchitectureDocs` 스킴)

## lat.md 지식 그래프 — 작업 워크플로우

도메인 지식·설계 의도는 `lat.md/` 그래프(도구: [lat.md](https://www.npmjs.com/package/lat.md), `lat --help`)에 산다. **코드와 그래프를 끊지 않는 게 핵심.**

- **작업 시작 전**: `lat search "<할 일>"` 로 관련 섹션을 찾아 설계 의도부터 파악(LLM 키 없으면 `lat locate`/`lat section`). 프롬프트의 `[[ref]]` 는 `lat expand` 로 펼쳐 맥락 확보.
- **작업 후 (필수)**: 기능/아키텍처/동작을 바꿨으면 해당 `lat.md/*.md` 노드를 갱신하고 **`lat check` 통과**(끊긴 링크·코드 ref 0). 통과 전엔 작업 완료로 보지 않는다.
- **코드 ↔ 그래프 앵커**: Reducer 선언부 위에 `// @lat: [[domain#Section]]`(소속), cross-feature 의존은 `// depends-on: [[…]]`(`import` 에 안 보이므로 명시).
- **작성 규칙**: 섹션 ID = **헤딩 텍스트 전체** → 헤딩에 ⚠️·괄호 등 데코레이션 금지. 모든 섹션은 **≤250자 선행 문단**으로 시작(`lat check` 강제). 상세 → `docs/lat-labeling.md`.
- 역참조 추적: `lat refs <id>` / `make lat q=<domain>`.

## 컨벤션

- **커밋**: 제목 1 줄 한국어. `type: 설명_부연` 형식. 본문은 정말 필요할 때만 2-3 줄.
- **public 키워드**: 모듈 경계를 넘는 타입/함수에 필수
- **Action 네이밍**: 사용자 입력 `userTapped...`, 응답 `...Loaded` / `...Saved`, 생명주기 `onAppear` / `onDisappear`, 부모/코디네이터 통보 `delegate(Delegate)`
- **Dependency `testValue`**: 반드시 `unimplemented`. 빈 클로저 금지
- **DesignSystem 토큰 우선**: `Color.dsPrimary`, `Font.dsBody`, `CGFloat.dsL`, `PrimaryButton` 등. 하드코딩 (`Color.blue`, `16`) 지양
- **@lat 주석 / lat.md 그래프**: 코드 변경 후 `@lat:` 라벨과 `lat.md/` 노드를 갱신하고 `lat check` 통과 (위 «lat.md 지식 그래프» 워크플로우 참조). cross-feature delegate 의존은 `import` 에 안 보이므로 `depends-on:` 으로 반드시 명시

## 디자인 시스템

디자인 토큰·표준 컴포넌트는 `Shared/SharedDesignSystem` 모듈(이관 대기 — 현재 골격만)에 산다. 모든 레이어가 `.shared(interface: .designSystem)` 로 의존 가능.

- 색상: `Color.dsPrimary` / `dsBackground` / `dsTextPrimary` / `dsTextSecondary`
- 타이포: `Font.dsLargeTitle` ~ `dsCaption` (8 단계)
- spacing: `CGFloat.dsXS` (4) ~ `dsXXL` (32)
- 컴포넌트: `PrimaryButton`
- 에셋 로드: 새 색·이미지는 `Resources/Colors.xcassets`·`Assets.xcassets` 에 추가 후 `Color.load(_:)`·`Image.load(_:)` 단일 seam 으로 토큰 노출 (번들 해석 일원화 + 개발 빌드 `assert` 로 오타 검출). 이미지 토큰은 `Image.DS` 네임스페이스 — 늘어나면 `Ic`/`Img` 중첩 enum 으로 묶는다 (GmoneyTrans 방식)

## 참고

- 자세한 패턴/개념은 `Projects/App/Documentation/Architecture.docc/` DocC 카탈로그 (전용 `ArchitectureDocs` 타겟이 호스팅. 현재 Tuist TMA 구조·코드 기준으로 현행화됨)
- 첫 빌드/세팅 `docs/getting-started.md`, 모듈 추가 `docs/adding-module.md`, 기획→아키텍처 매핑 작업 문서 `docs/work/`, 팀 컨벤션 `CONTRIBUTING.md`, 도메인 지식·의존 그래프 `lat.md/`(진입점 `lat.md/lat.md`, `lat check` 로 검증), lat 방법론 `docs/lat-methodology.md`, 코드 라벨 규칙 `docs/lat-labeling.md`, TMA 학습 노트 `docs/notes/`
- 개발계/운영계 환경 분리는 DocC `Environments` 아티클 (`Architecture.docc/Articles/HowTo/Environments.md`) — xcconfig + `@Dependency(\.appConfig)`, Feature 는 환경 무관
- modular architecture 스펙트럼에서 이 프로젝트는 Tuist 멀티프로젝트 TMA (Level 3+, 레이어 × Interface/Implementation)
- **문서 배치 규칙**: 심볼·개념·Xcode 렌더링이면 **DocC**, 검증되는 도메인 지식이면 **`lat.md/`**, 코드 밖 독립 산문(세팅·과정·외부·방법론)이면 **`docs/`**. 커밋/PR 규칙 단일 소스는 `CONTRIBUTING.md`
