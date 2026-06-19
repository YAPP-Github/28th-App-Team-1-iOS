# Architecture — Claude 작업 가이드

SwiftUI + TCA 레퍼런스 사이드 프로젝트. **Tuist 기반 µFeature(마이크로 피처) 아키텍처** — 화면 도메인을 독립 모듈로 분리하고, Feature 간 결합을 코디네이터가 중재한다.

## 프로젝트 구조

```
Workspace.swift                          ← Projects/** glob 통합
Tuist/Package.swift                      ← 외부 의존 (ComposableArchitecture)
Tuist/ProjectDescriptionHelpers/         ← Project.feature/.client/.core + 타입드 의존 액세서
Projects/
├── App/                                   composition root
│   ├── Sources/ArchitectureApp.swift        @main — *ClientLive link → liveValue 활성화
│   ├── AppFeature/                          탭 코디네이터 + cross-feature 라우팅
│   └── Documentation/                       ArchitectureDocs 타겟 — 전역 DocC 카탈로그 (코드 없음)
├── Feature/{Home,Users,Profile,Activity}/   화면 도메인 (Sources+Testing+Tests+Example)
├── Client/{User,Profile,Activity}Client/    Repository (Interface + Live 분리)
└── Shared/{Models, DesignSystemKit}/        도메인 모델 + 디자인 토큰
```

의존 방향: `App → AppFeature → *Feature → *ClientInterface → Models`. 전 모듈이 `DesignSystemKit` 의존 가능.

## 핵심 아키텍처 규칙 (절대 위반 금지)

- **Feature → Feature 의존 0.** 다른 Feature 로의 전환은 직접 하지 않고 `delegate` 로 신호만 올린다. cross-feature 조립은 **`AppFeature`(코디네이터)에서만**. (예: `UsersFeature` 가 `.delegate(.editProfile(id))` 방출 → AppFeature 가 앱 레벨 sheet 로 `ProfileFeature` 제시 → 저장 결과를 `.users(.profileUpdated)` 로 통보)
- **Feature 는 `*ClientInterface` 만 의존.** `*ClientLive`(실제 구현)는 **App 타겟 / Example 앱만** link. Feature·AppFeature 는 Live 를 절대 import 하지 않는다.
- **Client 만 Interface/Live 분리.** Feature 는 단일 모듈(+Testing/Tests/Example), Interface/구현 분리 안 함.

## 패턴 — 순수 TCA

- 화면 1개당 파일 2개: `XxxFeature.swift` (Reducer) + `XxxView.swift` (View)
- Reducer 가 비즈니스 로직 + 도메인 내부 navigation 처리. 도메인 안 navigation 은 그 Feature 자체 `Path` + `StackState` 로.
- 외부 IO 는 항상 `@Dependency` 로 주입. Client 는 별도 모듈(Interface + Live)
- `@ObservableState` + `@Bindable var store` 표준. `WithViewStore` 금지

## 새 화면/모듈 추가 흐름

1. (모델) `Projects/Shared/Models/Sources/Xxx.swift`
2. (외부 IO) `Projects/Client/XxxClient/{Interface,Live}/` + `Project.swift` → `Project.client(name: "XxxClient")`
3. (화면) `Projects/Feature/Xxx/{Sources,Testing,Tests,Example}/` + `Project.swift` → `Project.feature(name: "Xxx", dependencies: […], exampleDependencies: […])`
4. cross-feature 전환이면 그 Feature 에 `delegate` case 추가 → `AppFeature` 가 수신/조립. 새 탭이면 `AppFeature.State`/`Tab`/`AppView` 에 추가
5. `Tuist/ProjectDescriptionHelpers/TargetDependency+Module.swift` 에 의존 액세서가 없으면 추가 → `tuist generate`

각 모듈 `Project.swift` 는 헬퍼 호출 ~5줄. target 을 직접 나열하지 않는다.

## 빌드 / 실행

- 프로젝트 생성: `tuist install && tuist generate` (xcworkspace/xcodeproj 는 생성물 — 커밋 안 함)
- 빌드: `xcodebuild -workspace Architecture.xcworkspace -scheme Architecture -destination 'generic/platform=iOS Simulator' build`
- 테스트: `make test scheme=HomeFeature` 권장 (사용 가능한 시뮬레이터 UDID 로 해석 — 기기 이름이 여러 OS 런타임에 중복돼도 안전). 직접 xcodebuild 쓸 때 `name=iPhone 16` 이 중복으로 "Unable to find a device" 나면 `,OS=18.0` 또는 `id=<UDID>` 로 지정
- Feature 단독 실행: `*FeatureExample` 스킴
- DocC: Xcode 의 Product → Build Documentation

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
- **DesignSystemKit 토큰 우선**: `Color.dsPrimary`, `Font.dsBody`, `CGFloat.dsL`, `PrimaryButton` 등. 하드코딩 (`Color.blue`, `16`) 지양
- **@lat 주석 / lat.md 그래프**: 코드 변경 후 `@lat:` 라벨과 `lat.md/` 노드를 갱신하고 `lat check` 통과 (위 «lat.md 지식 그래프» 워크플로우 참조). cross-feature delegate 의존은 `import` 에 안 보이므로 `depends-on:` 으로 반드시 명시

## 디자인 시스템

`Shared/DesignSystemKit/` 가 색상/타이포/spacing 토큰 + 표준 컴포넌트 보유. 모든 Feature 가 의존 가능.

- 색상: `Color.dsPrimary` / `dsBackground` / `dsTextPrimary` / `dsTextSecondary`
- 타이포: `Font.dsLargeTitle` ~ `dsCaption` (8 단계)
- spacing: `CGFloat.dsXS` (4) ~ `dsXXL` (32)
- 컴포넌트: `PrimaryButton`

## 참고

- 자세한 패턴/튜토리얼은 `Projects/App/Documentation/Architecture.docc/` DocC 카탈로그 (전용 `ArchitectureDocs` 타겟이 호스팅. 현재 Tuist µFeature 구조·코드 기준으로 현행화됨)
- 첫 빌드/세팅 `docs/getting-started.md`, 기획→아키텍처 매핑 작업 문서 `docs/work/`, 팀 컨벤션 `CONTRIBUTING.md`, 도메인 지식·의존 그래프 `lat.md/`(진입점 `lat.md/lat.md`, `lat check` 로 검증), lat 방법론 `docs/lat-methodology.md`, 코드 라벨 규칙 `docs/lat-labeling.md`
- 개발계/운영계 환경 분리는 DocC `Environments` 아티클 (`Architecture.docc/Articles/HowTo/Environments.md`) — xcconfig + `@Dependency(\.appConfig)`, Feature 는 환경 무관
- modular architecture 스펙트럼에서 이 프로젝트는 Tuist 멀티프로젝트 µFeature (Level 3)
- **문서 배치 규칙**: 심볼·튜토리얼·Xcode 렌더링이면 **DocC**, 검증되는 도메인 지식이면 **`lat.md/`**, 코드 밖 독립 산문(세팅·과정·외부·방법론)이면 **`docs/`**. 커밋/PR 규칙 단일 소스는 `CONTRIBUTING.md`
