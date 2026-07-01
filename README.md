# Architecture

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트.
**Tuist 기반 TMA(The Modular Architecture)** 로, 앱을 `Core / Domain / Feature / Shared` 레이어로 나누고 각 모듈을 `Interface`(계약) / `Implementation`(구현)으로 분리한다. Feature 간 결합은 코디네이터(`AppFeature`)가 중재한다.

> **현재 상태**: `refactor/#6` 은 TMA **스켈레톤** 단계다. `FeatureHome` 과 레이어별 `*Common` 골격만 실체가 있고, 나머지 도메인은 이 골격이 찍어낼 표준형이다.

## 요구 사항

- [Tuist](https://tuist.io) 4.x (`mise install tuist` 또는 `brew install --cask tuist`)
- Xcode (iOS 26 SDK) / iOS 26 시뮬레이터 (deployment target)
- 의존성: [pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) (Tuist 가 자동 해결)

## 빌드 & 실행

```bash
# 1) 외부 의존 해석 + Xcode 프로젝트 생성
tuist install
tuist generate

# 2) 앱 빌드
xcodebuild -workspace App.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

- `App.xcworkspace` / 각 `*.xcodeproj` 는 **Tuist 생성물**이라 커밋하지 않는다. clone 후 `tuist generate` 로 만든다.
- 각 Feature 는 단독 실행용 **Example 앱 스킴**(예: `FeatureHomeExample`)을 갖는다.

## 프로젝트 구조 (TMA)

```
Workspace.swift                              # Projects/** glob 통합
Plugins/DependencyPlugin/…/Modules.swift     # 모듈 레지스트리(ModulePath) — 새 모듈은 여기 먼저 등록
Tuist/
  ├── Package.swift                          # 외부 의존 (ComposableArchitecture)
  ├── ProjectDescriptionHelpers/             # Project.makeModule + Target 팩토리(.app/.core/.domain/.feature/.shared)
  └── Templates/                             # tuist scaffold 용 레이어별 스텐실
Projects/
  ├── App/                                   # composition root (App @main + AppFeature + Config + Documentation)
  ├── Core/    {CoreCommon,…}                 # 인프라 (네트워킹 등)
  ├── Domain/  {DomainCommon,…}                  # 도메인 모델 + Repository(Client)
  ├── Feature/ {FeatureCommon, FeatureHome,…}     # 화면 도메인 (단일 모듈)
  └── Shared/  {SharedCommon, SharedDesignSystem,…} # 디자인 토큰 등 공용
```

Domain·Core·Shared 모듈은 `{Layer}{Name}Interface` / `Implementation` / `Testing` / `Tests` 타겟 세트를 갖고, **Feature 는 Interface 없이** 구현 + `Testing`/`Tests`/`Example` 로 둔다. 레이어 루트의 `Projects/{Layer}/Project.swift` 는 하위 구현을 `@_exported` 로 재노출하는 **umbrella** 로, **App/Example 만** link 한다.

### 의존 규칙

- **Feature → Feature 의존 0.** 화면 전환이 필요하면 `delegate` 로 신호만 보내고, `AppFeature`(코디네이터)가 앱 레벨에서 조립한다. (예: Users 상세의 "프로필 편집" → 앱 레벨 sheet 로 `ProfileFeature` 제시)
- **Domain·Core·Shared 는 Interface/Implementation 분리, Feature 는 단일 모듈.** 다른 레이어는 **Interface 만** 의존한다 (`.domain(interface:)`, `.core(interface:)`, `.shared(interface:)`). 구현(`*Implementation`)은 **App/Example 만** link → `liveValue` 활성화. Feature 가 Interface 를 안 두는 이유(TCA 리듀서는 Interface 로 못 가림)는 [FeatureInterface](Projects/App/Documentation/Architecture.docc/Architecture/FeatureInterface.md).
- 의존 방향: `App → *Feature → Domain(interface) → Core(interface)`. `Shared(interface)` 는 전 레이어 의존 가능.

새 모듈 추가는 [`docs/adding-module.md`](docs/adding-module.md) 참고 — `Modules.swift` 등록(→ umbrella 자동) → 모듈 `Project.swift` → `Source.swift` 재노출 → `tuist generate`.

## 테스트

```bash
xcodebuild -workspace App.xcworkspace -scheme FeatureHome \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

각 모듈 스킴(`FeatureHome` / `DomainCommon` …)의 Test 액션이 그 모듈의 `*Tests` 를 포함한다. `make test scheme=FeatureHome` 가 시뮬레이터 UDID 해석까지 해줘 편하다.

## DocC 문서

개념 아티클·심볼 주석은 `Projects/App/Documentation/Architecture.docc/` 카탈로그에 있다 (전용 `ArchitectureDocs` 타겟이 호스팅).
`tuist generate` 후 Xcode 에서 `ArchitectureDocs` 스킴 선택 → **Product → Build Documentation** (⌃⇧⌘D).

> DocC 카탈로그는 현재 Tuist TMA 구조·코드 기준으로 정리되어 있다.

## 문서 지도

문서는 독자별로 레이어가 나뉜다. 같은 내용을 중복 작성하지 않고 서로 링크한다.

| 문서 | 위치 | 무엇을 / 누구를 위해 |
|---|---|---|
| **README** | (여기) | 프로젝트 소개·빌드·구조·의존 규칙 — 처음 오는 사람의 현관 |
| **첫 빌드 가이드** | [`docs/getting-started.md`](docs/getting-started.md) | clone 직후 처음 빌드까지의 단계별 셋업 |
| **모듈 추가 가이드** | [`docs/adding-module.md`](docs/adding-module.md) | 새 레이어/서브모듈 추가 체크리스트 |
| **기여 가이드** | [`CONTRIBUTING.md`](CONTRIBUTING.md) | 브랜치·커밋·PR·리뷰·배포 등 팀 협업 규칙 |
| **DocC 카탈로그** | [`Architecture.docc/`](Projects/App/Documentation/Architecture.docc) | 심볼 레퍼런스·개념 아티클 (Xcode 에서 봄) |
| **도메인 지식 그래프** | [`lat.md/`](lat.md/lat.md) | 도메인 스펙·설계 결정·cross-feature 숨은 의존 (lat.md 도구 · `lat check`). 방법론은 [`docs/lat-methodology.md`](docs/lat-methodology.md) |
| **작업 문서** | [`docs/work/`](docs/work) | 기획서 → 아키텍처 매핑 작업 문서 (AI 면접 등) |
| **스터디 노트** | [`docs/notes/`](docs/notes) | 외부 아키텍처 비교 학습 메모 (이 프로젝트 설명 아님) |
| **에이전트 가이드** | [`.claude/CLAUDE.md`](.claude/CLAUDE.md) | Claude 가 따르는 작업 규칙 |

> **어디에 쓰나 (DocC vs lat.md vs docs)** — 셋이 헷갈리면 이 순서로 판단한다:
> 1. 코드 심볼 링크·개념·Xcode 렌더링으로 더 좋아지나? → **DocC** (이 코드를 *배우는* 것)
> 2. 코드와 동기화 *검증*이 필요한 "도메인이 무엇·무슨 결정"인가? → **`lat.md/`** (`lat check`)
> 3. 둘 다 아닌, 코드 밖에서 읽는 **독립 산문**(세팅·과정·외부 노트·방법론)인가? → **`docs/`**

## 커밋 규칙

제목 1줄 한국어 `type: 설명_부연` 형식. 본문은 정말 필요할 때만 2-3줄. (전체 규칙·type 목록의 **단일 소스**는 [`CONTRIBUTING.md`](CONTRIBUTING.md) §1.2)
