# Architecture — Claude 작업 가이드

SwiftUI + TCA · **Tuist TMA** — `Core / Domain / Feature / Shared` 4 레이어. Domain·Core·Shared 는 `Interface`(계약)/`Implementation`(구현) 분리, Feature 는 단일 모듈. cross-feature 조립은 `AppFeature`(코디네이터) 전담.

## 구조 (현행)

```
Plugins/DependencyPlugin/ … Modules.swift    ← 모듈 레지스트리(ModulePath) — 새 모듈은 여기 먼저
Tuist/                                       ← Project.makeModule + 타겟 팩토리 + scaffold 템플릿
Projects/
├── App/       composition root — AppFeature(탭 코디네이터) · Config/{Dev,QA,Prod}.xcconfig · DocC
├── Core/      Common · Network
├── Domain/    Common · Auth · Interview · JD · Job · Portfolio    (모델 + Client)
├── Feature/   Common · Home · Auth · Onboarding                   (화면 — Interface 없음)
└── Shared/    Common · DesignSystem (타이포+컬러+이미지 토큰 구현됨)
```

- 의존 방향: `App → Feature(Impl) → Domain(Interface) → Core(Interface)`. `Shared(Interface)` 는 전 레이어 가능.
- 레이어 umbrella(`Projects/{Layer}/Project.swift`, `@_exported` 재노출)·Implementation 은 **App/Example 만** link.

## 절대 규칙

- **Feature → Feature 의존 0** — 전환은 `delegate` 신호만 올리고, 조립은 AppFeature 에서.
- 타 모듈은 **Interface 만** 의존: `.domain(interface: .job)` 식. Implementation·umbrella import 금지.
- **Feature 는 Interface 없음 (D3)** — Reducer/View 는 `Sources/` 한 타겟에.
- **Repository(외부 IO) = Domain 모듈** — Interface 에 Client struct + DependencyValues 키 + preview/testValue, Implementation 에 liveValue.
- **구조 변경 시 문서 동기화 (필수)** — 모듈 추가/삭제, 의존 방향, 레이어 규칙 등 구조 관련 코드가 바뀌면 **같은 작업 안에서** 이 파일의 «구조» 섹션 + `docs/adding-module.md`(절차 변경 시) + 관련 `lat.md/` 노드를 갱신한다. 문서가 코드와 어긋난 채로 작업을 끝내지 않는다.

## TCA 패턴

- 화면 1개 = `XxxFeature.swift`(Reducer) + `XxxView.swift`(View).
- **Action 3분류 (D5)**: `view`(사용자 입력·생명주기 — View 의 `send` 전용) / `inner`(effect 결과 — 리듀서 전용) / `delegate`(부모 통보 — 부모는 이것만 매칭). `async` 카테고리 금지(응답은 inner). binding 은 `View: BindableAction` + `BindingReducer(action: \.view)`. switch 길어지면 `reduceView`/`reduceInner` 분리.
- `@ObservableState` + `@Bindable var store` + `@ViewAction(for:)` 표준. `WithViewStore` 금지.
- 외부 IO 는 `@Dependency` 주입. `testValue` 는 반드시 unimplemented (빈 클로저 금지).
- 도메인 내부 navigation 은 그 Feature 의 `Path`/`StackState` 로.

## 새 모듈

`make scaffold-{feature|domain|core|shared} name=X` → ① `Modules.swift` 에 case 등록 ② `Projects/{Layer}/Sources/Source.swift` 에 `@_exported import …Implementation` 추가 ③ `tuist generate`. 상세 체크리스트: `docs/adding-module.md` (단일 소스).

## 빌드 / 실행

- `tuist install && tuist generate` — `.xcworkspace`/`.xcodeproj` 는 생성물, 커밋 안 함.
- 앱 스킴 `Hilit-Dev|QA|Prod`. Feature 단독 실행: `Feature{Name}` 스킴 ⌘R (Example 앱이 실행 타겟).
- 테스트: `make test scheme=FeatureHome` 권장 (시뮬레이터 UDID 자동 해석).
- **umbrella 의존 변경 후 `tuist generate` 필수** — 캐시 그래프 빌드는 "거짓 성공".
- DocC: `ArchitectureDocs` 스킴 → Product → Build Documentation.
- - **PR 올리기**: base 는 항상 `dev`(feature→dev). `gh pr create --repo YAPP-Github/28th-App-Team-1-iOS --base dev --head "$(git branch --show-current)" --title "type: 요약" --body-file <본문.md>` — 본문은 `.github/pull_request_template.md` 형식으로 채운다(관련 이슈 `Close #N` / 작업 내역 / 리뷰 포인트 / 체크리스트). 규칙 상세는 `CONTRIBUTING.md`, 머지는 squash. gh 미인증이면 `gh auth login` 먼저.

## lat.md 지식 그래프

- 작업 전 `lat search "<할 일>"` 로 설계 의도 파악. 작업 후 관련 노드 갱신 + **`lat check` 통과 전엔 미완료**.
- Reducer 위 `// @lat: [[node#Section]]`, cross-feature delegate 의존은 `// depends-on: [[…]]` (import 에 안 보임).
- 섹션 헤딩 = ID (데코레이션 금지), 모든 섹션은 ≤250자 선행 문단으로 시작. 상세: `docs/lat-labeling.md`.

## 컨벤션

- **커밋**: 제목 1 줄 한국어. `type: 설명_부연` 형식. 본문은 정말 필요할 때만 2-3 줄.
- 네이밍: Swift API Design Guidelines. 외부 명칭(Figma 토큰 등)은 Swift 식별자화 + 원본은 매핑 프로퍼티 보존(`figmaName`). 테스트 함수 camelCase, 한글 설명은 `@Test("…")` 표시명.
- 모듈 경계 넘는 타입/함수는 `public` 필수.
- Action 네이밍: `userTapped…`(view) / `…Loaded`·`…Saved`(inner) / `onAppear`·`onDisappear`(view).
- **UI 작업 전 `.claude/design.md` 필독** — DS 토큰(`.dsTypography(.head1)`, `Color.dsBlack`, `Image.DS.icClose`) 우선, 하드코딩(`Color.blue`, `16`, `.font(.system(size:))`) 지양.

## 참고

- 패턴/개념: DocC `Projects/App/Documentation/Architecture.docc/` · 환경분리: DocC `Environments` 아티클
- 세팅 `docs/getting-started.md` · 모듈 추가 `docs/adding-module.md` · 커밋/PR `CONTRIBUTING.md` · lat 방법론 `docs/lat-methodology.md`
- 문서 배치: 심볼·개념 = **DocC**, 검증되는 도메인 지식 = **`lat.md/`**, 코드 밖 독립 산문 = **`docs/`**.
