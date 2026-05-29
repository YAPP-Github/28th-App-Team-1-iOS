# Architecture — Claude 작업 가이드

SwiftUI + TCA 레퍼런스 사이드 프로젝트. 단일 SPM 패키지 + 다중 target 의 modular architecture (Level 2).

## 프로젝트 구조

```
Architecture/                            ← App 타겟 (얇은 entry)
└── ArchitectureApp.swift                  AppFeature import 만 함
ArchitecturePackage/Sources/             ← 단일 SPM 패키지 (8 target)
├── App/AppFeature/                        탭 코디네이터 + DocC
├── Core/{Models, DesignSystemKit}/        도메인 모델 + 디자인 토큰
├── Data/{UserClient, ProfileClient}/      Repository (Dependency)
└── Feature/{Home, User, Activity, Profile}Feature/   화면 도메인
```

의존 방향: `AppFeature → *Feature → *Client → Models`. 전 target 이 `DesignSystemKit` 의존 가능.

## 패턴 — 순수 TCA

- 화면 1개당 파일 2개: `XxxFeature.swift` (Reducer) + `XxxView.swift` (View)
- Reducer 가 비즈니스 로직과 navigation 둘 다 처리 (RIBs 의 Interactor/Router 없음)
- 외부 IO 는 항상 `@Dependency` 로 주입. Client 는 별도 target
- `@ObservableState` + `@Bindable var store` 표준. `WithViewStore` 금지
- 도메인 안 navigation 은 그 도메인 Feature 가 자체 `Path` + `StackState` 로 처리. AppFeature 는 탭 전환만

## 새 화면 추가 흐름

1. `Sources/Core/Models/Xxx.swift` (필요 시)
2. `Sources/Data/XxxClient/XxxClient.swift` (외부 IO 필요 시)
3. `Sources/Feature/XxxFeature/{XxxFeature.swift, XxxView.swift}`
4. 호스트 Feature 의 `Path` enum + destination switch 에 case 추가 (탭 안 화면이면 그 탭 Feature, 새 탭이면 AppFeature)
5. `Package.swift` 에 target 등록 + 의존 명시 (`path: "Sources/Feature/XxxFeature"`)

자세한 단계와 코드 예시는 DocC 의 `<doc:AddingFeature>` / Tutorial 참조.

## 빌드 / 실행

- 빌드: `xcodebuild -workspace Architecture.xcworkspace -scheme Architecture -destination 'generic/platform=iOS Simulator' build`
- DocC preview: Xcode 의 Product → Build Documentation

## 컨벤션

- **커밋**: 제목 1 줄 한국어. `type: 설명_부연` 형식. 본문은 정말 필요할 때만 2-3 줄. (예: `refactor: Sources/ 를 App/Core/Data/Feature 4 layer 로 분리`)
- **public 키워드**: SPM target 경계를 넘는 타입/함수에 필수
- **Action 네이밍**: 사용자 입력 `userTapped...`, 응답 `...Loaded` / `...Saved`, 생명주기 `onAppear` / `onDisappear`, 부모 통보 `delegate(Delegate)`
- **Dependency `testValue`**: 반드시 `unimplemented`. 빈 클로저 금지
- **DesignSystemKit 토큰 우선**: `Color.dsPrimary`, `Font.dsBody`, `CGFloat.dsL`, `PrimaryButton` 등. 하드코딩 (`Color.blue`, `16`) 지양

## 디자인 시스템

`Core/DesignSystemKit/` 가 색상/타이포/spacing 토큰 + 표준 컴포넌트 보유. 모든 Feature 가 의존 가능.

- 색상: `Color.dsPrimary` / `dsBackground` / `dsTextPrimary` / `dsTextSecondary`
- 타이포: `Font.dsLargeTitle` ~ `dsCaption` (8 단계)
- spacing: `CGFloat.dsXS` (4) ~ `dsXXL` (32)
- 컴포넌트: `PrimaryButton`

## 참고

- 자세한 아키텍처 위치 / 패턴 / 새 Feature 추가 가이드는 `Sources/App/AppFeature/AppFeature.docc/` 의 DocC 카탈로그
- modular architecture 스펙트럼 안에서 이 프로젝트는 Level 2 상단 (단일 SPM + 8 target)
