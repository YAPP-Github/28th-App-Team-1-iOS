# Architecture

SwiftUI + TCA(The Composable Architecture) 레퍼런스 프로젝트.
`UserList` → `UserDetail` → `Profile` 의 세 화면으로 Repository / Coordinator / Command / Observer 패턴과 화면 간 값 전달 3 가지 케이스를 보여준다.

## 요구 사항

- Xcode 16+ (현재 동작 확인: Xcode 26.4)
- iOS 17+ 시뮬레이터
- 의존성: [pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.15+ (SPM 으로 자동 해결)

## 빌드 & 실행

```bash
# 시뮬레이터 빌드
xcodebuild build \
  -project Architecture.xcodeproj \
  -scheme Architecture \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -skipMacroValidation
```

Xcode GUI 로 처음 열면 TCA 매크로 fingerprint 승인 다이얼로그가 한 번 뜬다. "Trust & Enable" 클릭하면 영구히 해결.

## DocC 문서 보는 법

이 프로젝트의 모든 가이드·튜토리얼·심볼 주석은 DocC 카탈로그 (`Architecture/Architecture.docc/`) 에 들어 있다.

### Xcode 에서 (권장)

1. Xcode 에서 프로젝트를 연다.
2. 메뉴: **Product → Build Documentation** — 또는 단축키 **⌃⇧⌘D**.
3. 빌드가 끝나면 **⌥⇧⌘0** 으로 Developer Documentation 창을 연다.
4. 좌측 트리에서 **Workspace Documentation → Architecture** 를 펼치면 다음이 보인다.
   - **Articles** — `AddingFeature`, `NavigationPatterns`, `CommitConvention`
   - **Tutorials** — `AddingFeatureTutorial` (5 step, 10 분), `NavigationPatternsTutorial` (3 section, 15 분)
   - 각 타입(`AppFeature`, `UserClient`, `ProfileFeature` 등) 의 심볼 문서

### 커맨드라인에서

```bash
xcodebuild docbuild \
  -project Architecture.xcodeproj \
  -scheme Architecture \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -derivedDataPath build \
  -skipMacroValidation

# 결과: build/Build/Products/Debug-iphonesimulator/Architecture.doccarchive
open build/Build/Products/Debug-iphonesimulator/Architecture.doccarchive
```

### GitHub Pages 로 배포

```bash
$(xcrun --find docc) process-archive transform-for-static-hosting \
  build/Build/Products/Debug-iphonesimulator/Architecture.doccarchive \
  --output-path docs \
  --hosting-base-path <repo-name>
```

생성된 `docs/` 를 `gh-pages` 브랜치에 push 하고 저장소 **Settings → Pages** 에서 source 를 `gh-pages /(root)` 로 지정하면 다음 URL 에 배포된다.

```
https://<user>.github.io/<repo-name>/documentation/architecture/
```

## 프로젝트 구조

```
Architecture/
├── App/                    # AppFeature(Coordinator) + @main
├── Domain/                 # User, Profile
├── Dependencies/           # UserClient, ProfileClient (Repository)
├── Features/
│   ├── UserList/           # 목록 — Case B 트리거
│   ├── UserDetail/         # 상세 — Case B 수신 + Case A 트리거
│   └── Profile/            # 편집 — Case A 수신 + Case C 트리거
└── Architecture.docc/      # 가이드/튜토리얼/심볼 주석 카탈로그
```

## 커밋 규칙

<doc:CommitConvention> 참고. 요약하면 `<type>: <subject>_<detail>` 형식에 본문은 `-` bullet, 푸터는 `resolves: #N` / `ref: #N` 형태.
