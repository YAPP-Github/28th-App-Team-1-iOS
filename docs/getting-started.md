# 첫 빌드 세팅 가이드

clone 직후 **처음 빌드까지** 그대로 따라 하면 되는 문서. (아키텍처 설명은 [`README.md`](../README.md), 팀 규칙은 [`CONTRIBUTING.md`](../CONTRIBUTING.md), 도메인 지식은 [`lat.md/`](../lat.md) 참고)

> 핵심: `.xcworkspace`/`.xcodeproj` 는 **커밋되지 않습니다.** Tuist 생성물이라 clone 후 직접 만들어야 합니다.

---

## 0. 전제 (한 번만)

| 도구 | 용도 | 설치 |
|---|---|---|
| Xcode (iOS 26 SDK) | iOS 26 시뮬레이터 | App Store |
| Homebrew | 패키지 매니저 | https://brew.sh |
| **Tuist 4.x** | 프로젝트 생성 (필수) | `brew install --cask tuist` 또는 `mise install tuist` |
| **SwiftLint** | 빌드 시 자동 린트 (없으면 경고만, 빌드는 됨) | `brew install swiftlint` |
| ripgrep | `make lat` 검색 가속 (선택) | `brew install ripgrep` |

```bash
brew install --cask tuist
brew install swiftlint
brew install ripgrep        # 선택
```

---

## 1. 최초 셋업 (clone 직후)

```bash
git clone https://github.com/YAPP-Github/28th-App-Team-1-iOS.git
cd 28th-App-Team-1-iOS

# 1) 외부 의존(SPM) 해석 — ComposableArchitecture 등
tuist install

# 2) Xcode 워크스페이스/프로젝트 생성
tuist generate
```

`make generate` 한 줄로 위 두 명령을 한 번에 돌릴 수도 있습니다.

생성이 끝나면 `App.xcworkspace` 가 만들어지고 자동으로 Xcode 가 열립니다. (안 열리면 `open App.xcworkspace`)

---

## 2. 첫 빌드 & 실행

**Xcode 에서:**
1. 스킴 선택 → **`App`**
2. 시뮬레이터(iPhone 16 등) 선택 → **⌘R**

**터미널에서:**
```bash
xcodebuild -workspace App.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

> ⏱️ **첫 빌드는 수 분 걸립니다.** ComposableArchitecture 가 의존하는 **swift-syntax 매크로 컴파일**이 처음에 통째로 돌기 때문이고, 정상입니다. 두 번째부터는 캐시되어 빠릅니다.

### 화면(Feature) 단독 실행
각 Feature 는 단독 실행용 **Example 앱 스킴**이 있습니다: `Feature{Name}Example` (현재 골격에선 `FeatureHomeExample`) → 선택 후 ⌘R.

### 개발계 / QA / 운영계
빌드 Configuration `Dev` / `QA` / `Release` 로 나뉩니다 (`Dev` 에만 `DEV` 컴파일 조건). 스킴의 Run 구성에서 Configuration 을 바꿔 전환합니다. 동작 원리·값 주입(`@Dependency(\.appConfig)`)·확장법은 DocC `Environments` 아티클 (`ArchitectureDocs` 스킴 → Build Documentation) 참고.

---

## 3. 자주 겪는 문제

| 증상 | 원인 / 해결 |
|---|---|
| `App.xcworkspace` 가 없다 | `tuist generate` 안 함. → 1번 실행 |
| 빌드 중 `SwiftLint 미설치` 경고 | `brew install swiftlint` (없어도 빌드는 됨 — 경고만) |
| 첫 빌드가 너무 오래 걸림 | 정상 (swift-syntax 매크로 첫 컴파일). 기다리면 됨 |
| 의존성/모듈을 못 찾음 | `tuist install` 다시 → `tuist generate`. 그래도면 `tuist clean` 후 재시도 |
| 새 모듈을 추가했는데 빌드에 안 잡힘 | `Modules.swift` 등록 + 레이어 umbrella 에 Implementation 추가했는지 확인 → `tuist generate` 재실행 |
| umbrella 를 고쳤는데 반영 안 됨 | 캐시된 그래프로 빌드된 것. **`tuist generate` 를 반드시 다시** 돌린다 |
| 파일 추가했는데 Xcode 에 안 보임 | Tuist 는 글롭으로 소스를 잡음. `tuist generate` 다시 실행 |

---

## 4. 자주 쓰는 명령 (Makefile)

```bash
make generate                        # tuist install + generate
make test scheme=FeatureHome         # 특정 모듈 테스트 (시뮬레이터 UDID 자동 해석)
make lint                            # 전 모듈 SwiftLint
make lint-fix                        # 자동 수정 + 린트
make lat q=home                      # home 도메인과 엮인 코드 검색 (lat.md)
make lat-deps q=home                 # home 을 바꾸면 영향받는 곳
```

---

## 5. 다음 단계

- 아키텍처/의존 규칙 → [`README.md`](../README.md)
- 새 모듈 추가 → [`docs/adding-module.md`](adding-module.md)
- 팀 컨벤션(브랜치·커밋·PR·배포) → [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 도메인 지식·흐름·의존 인덱스 → [`lat.md/`](../lat.md) (+ `make lat`)
- 개념 아티클 문서 → Xcode 에서 `ArchitectureDocs` 스킴 → **Product → Build Documentation** (⌃⇧⌘D)
