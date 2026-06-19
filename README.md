# Architecture

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트.
**Tuist 기반 µFeature(마이크로 피처) 아키텍처**로, 화면 도메인을 독립 모듈로 분리하고 Feature 간 결합을 코디네이터가 중재하는 패턴을 보여준다.

## 요구 사항

- [Tuist](https://tuist.io) 4.x (`mise install tuist` 또는 `brew install --cask tuist`)
- Xcode 16+ / iOS 17+ 시뮬레이터
- 의존성: [pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.15+ (Tuist 가 자동 해결)

## 빌드 & 실행

```bash
# 1) 외부 의존 해석 + Xcode 프로젝트 생성
tuist install
tuist generate

# 2) 앱 빌드
xcodebuild -workspace Architecture.xcworkspace -scheme Architecture \
  -destination 'generic/platform=iOS Simulator' build
```

- `Architecture.xcworkspace` / 각 `*.xcodeproj` 는 **Tuist 생성물**이라 커밋하지 않는다. clone 후 `tuist generate` 로 만든다.
- 각 Feature 는 단독 실행용 **Example 앱 스킴**(`HomeFeatureExample`, `UsersFeatureExample`, `ProfileFeatureExample`, `ActivityFeatureExample`)을 갖는다.

## 프로젝트 구조 (µFeature)

```
Workspace.swift                         # Projects/** glob 통합
Tuist/
  ├── Package.swift                      # 외부 의존 (ComposableArchitecture)
  └── ProjectDescriptionHelpers/         # Project.feature/.client/.core + 타입드 의존
Projects/
  ├── App/                               # composition root
  │   ├── Sources/ArchitectureApp.swift  #   @main — *ClientLive link 으로 liveValue 활성화
  │   ├── AppFeature/                     #   탭 코디네이터 + cross-feature 라우팅
  │   └── Documentation/                  #   ArchitectureDocs 타겟 — 전역 DocC 카탈로그
  ├── Feature/{Home,Users,Profile,Activity}/   # 화면 도메인 (Sources+Testing+Tests+Example)
  ├── Client/{User,Profile,Activity}Client/    # Repository (Interface + Live 분리)
  └── Shared/{Models,DesignSystemKit}/         # 도메인 모델 + 디자인 토큰
```

### 의존 규칙

- **Feature → Feature 의존 0.** 화면 전환이 필요하면 `delegate` 로 신호만 보내고, `AppFeature`(코디네이터)가 앱 레벨에서 조립한다. (예: Users 상세의 "프로필 편집" → 앱 레벨 sheet 로 `ProfileFeature` 제시)
- **Feature 는 `*ClientInterface` 만 의존.** `*ClientLive`(실제 구현)는 **App 타겟 / Example 앱만** link → `liveValue` 활성화.
- 의존 방향: `App → AppFeature → *Feature → *ClientInterface → Models`. 전 모듈이 `DesignSystemKit` 의존 가능.

새 화면/모듈 추가 방법은 `Tuist/ProjectDescriptionHelpers/` 의 `Project.feature` / `Project.client` / `Project.core` 헬퍼를 참고. 각 모듈 `Project.swift` 는 이름과 의존만 넘기는 ~5줄짜리다.

## 테스트

```bash
xcodebuild -workspace Architecture.xcworkspace -scheme UsersFeature \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Feature 스킴(`HomeFeature` / `UsersFeature` / `ProfileFeature` / `ActivityFeature`)의 Test 액션이 각 `*FeatureTests` 를 포함한다.

## DocC 문서

가이드·튜토리얼·심볼 주석은 `Projects/App/Documentation/Architecture.docc/` 카탈로그에 있다 (전용 `ArchitectureDocs` 타겟이 호스팅).
`tuist generate` 후 Xcode 에서 `ArchitectureDocs` 스킴 선택 → **Product → Build Documentation** (⌃⇧⌘D).

> DocC 카탈로그는 현재 Tuist µFeature 구조·코드 기준으로 정리되어 있다.

## 문서 지도

문서는 독자별로 레이어가 나뉜다. 같은 내용을 중복 작성하지 않고 서로 링크한다.

| 문서 | 위치 | 무엇을 / 누구를 위해 |
|---|---|---|
| **README** | (여기) | 프로젝트 소개·빌드·구조·의존 규칙 — 처음 오는 사람의 현관 |
| **첫 빌드 가이드** | [`docs/getting-started.md`](docs/getting-started.md) | clone 직후 처음 빌드까지의 단계별 셋업 |
| **기여 가이드** | [`CONTRIBUTING.md`](CONTRIBUTING.md) | 브랜치·커밋·PR·리뷰·배포 등 팀 협업 규칙 |
| **DocC 카탈로그** | [`Architecture.docc/`](Projects/App/Documentation/Architecture.docc) | 심볼 레퍼런스·튜토리얼·개념 아티클 (Xcode 에서 봄) |
| **도메인 지식 볼트** | [`lat.md/`](lat.md/README.md) | lat 방법론·도메인 흐름·cross-feature 숨은 의존 (Obsidian · `make lat`) |
| **작업 문서** | [`docs/work/`](docs/work) | 기획서 → 아키텍처 매핑 작업 문서 (AI 면접 등) |
| **스터디 노트** | [`docs/notes/`](docs/notes) | 외부 아키텍처 비교 학습 메모 (이 프로젝트 설명 아님) |
| **에이전트 가이드** | [`.claude/CLAUDE.md`](.claude/CLAUDE.md) | Claude 가 따르는 작업 규칙 |

## 커밋 규칙

제목 1줄 한국어 `type: 설명_부연` 형식. 본문은 정말 필요할 때만 2-3줄.
