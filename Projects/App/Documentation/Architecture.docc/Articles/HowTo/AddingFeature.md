# 새 Feature 추가하기

새 화면 도메인을 Domain + Feature 모듈로 더하는 표준 절차.

## Overview

`Profile` 화면을 예로 든다. TMA 구조라 새 화면은 보통 **Domain 모듈(데이터/Repository) + Feature 모듈(화면)** 한 쌍으로 추가한다. 모듈을 찍어내는 기계적 체크리스트는 `docs/adding-module.md` 가 단일 소스이고, 이 문서는 **TCA 관점의 무엇을 어디에 두나 + 코디네이터 연결**에 집중한다.

| 단계 | 위치 |
|---|---|
| 1 | `Modules.swift` 의 `ModulePath.Domain`·`.Feature` 에 case 등록 |
| 2 | `Projects/Domain/DomainProfile/{Interface,Sources}/` — 모델 + Client (외부 IO 있을 때) |
| 3 | `Projects/Feature/FeatureProfile/Sources/ProfileFeature.swift` (Reducer) |
| 4 | `Projects/Feature/FeatureProfile/Sources/ProfileView.swift` (View) |
| 5 | 두 모듈 `Project.swift` 작성 + umbrella `Source.swift` 재노출 → `tuist generate` |
| 6 | 호스트에 연결 — **새 탭**이면 ``AppFeature``, **다른 Feature 에서 진입**이면 `delegate` → ``AppFeature`` 가 제시 |

> Important: 화면이 다른 Feature 라면 그 Feature 를 직접 import/push 하지 않는다. **Feature → Feature 의존은 0** 이고, cross-feature 조립은 ``AppFeature`` 에서만 한다. (Step 6 참조)

---

## Step 1 — 레지스트리 등록

모든 모듈 추가의 시작점. 등록하지 않으면 타입드 액세서가 없어 `Project.swift` 에서 참조할 수 없다.

```swift
// Plugins/DependencyPlugin/ProjectDescriptionHelpers/Modules.swift
public enum Domain: String, CaseIterable {
    case common = "Common"
    case profile = "Profile"   // ← 추가 (rawValue = 디렉토리 접미사 → Projects/Domain/DomainProfile/)
}
public enum Feature: String, CaseIterable {
    case common = "Common"
    case profile = "Profile"   // ← 추가
}
```

## Step 2 — Domain 모듈 (모델 + Repository)

도메인 모델과 Client 는 Domain 레이어에 산다. **모델·Client 계약·`previewValue`/`testValue` 는 `Interface/`**, **`liveValue` 는 `Sources/`(Implementation)**. Client 는 리듀서가 아니라 클로저 struct 라 Interface/구현 분리가 매끄럽다(<doc:FeatureInterface> §9).

```swift
// Projects/Domain/DomainProfile/Interface/Profile.swift
public struct Profile: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public var displayName: String
    public var bio: String
    public init(id: Int, displayName: String, bio: String) { … }
}

// Projects/Domain/DomainProfile/Interface/ProfileClient.swift
public struct ProfileClient: Sendable {
    public var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    public var saveProfile:  @Sendable (_ profile: Profile) async throws -> Profile
    public init(…) { … }
}

extension ProfileClient: TestDependencyKey {
    public static let previewValue = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    public static let testValue = ProfileClient(
        fetchProfile: unimplemented("ProfileClient.fetchProfile", placeholder: .stub),
        saveProfile:  unimplemented("ProfileClient.saveProfile",  placeholder: .stub)
    )
}
extension DependencyValues {
    public var profileClient: ProfileClient {
        get { self[ProfileClient.self] } set { self[ProfileClient.self] = newValue }
    }
}
```

```swift
// Projects/Domain/DomainProfile/Sources/ProfileClient+Live.swift
import DomainProfileInterface
extension ProfileClient: DependencyKey {
    public static let liveValue = ProfileClient(fetchProfile: { … }, saveProfile: { … })
}
```

**주의** — 모듈 경계를 넘는 타입은 전부 `public`(`init` 포함) + `Sendable`. `testValue` 는 반드시 `unimplemented`(빈 클로저 금지). `liveValue` 는 `Implementation` 에만 두므로, App/Example 이 Domain umbrella 를 link 해야 런타임에 활성화된다.

## Step 3 — Reducer (`FeatureProfile/Sources/`)

```swift
// Projects/Feature/FeatureProfile/Sources/ProfileFeature.swift
import ComposableArchitecture
import DomainProfileInterface   // Domain Interface 만 의존

// @lat: [[profile]]
@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        public let profileId: Int
        public var profile: Profile?
        public var isLoading = false
        public init(profileId: Int) { self.profileId = profileId }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case userTappedSaveButton
        case profileLoaded(Profile)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case profileSaved(Profile)   // 결과를 위(코디네이터)로 통보
        }
    }

    @Dependency(\.profileClient) var profileClient
    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in /* … */ }
    }
}
```

**주의** — Action 네이밍: 입력 `userTapped...`, 응답 `...Loaded`/`...Saved`, 생명주기 `onAppear`/`onDisappear`, 상위 통보 `delegate(Delegate)`. 다른 Feature 로의 전환은 여기서 직접 하지 말고 `delegate` 로만 신호한다. 리듀서 선언부 위에 `// @lat: [[profile]]` 앵커를 단다.

## Step 4 — View

View 도 `Sources/` 에 둔다. **Feature 는 Interface 를 두지 않는다**(D3) — 다른 Feature 로 올릴 신호는 위 Reducer 의 `Action.Delegate` 로 표현하고, 코디네이터(AppFeature)가 그 delegate 를 받아 조립한다(<doc:FeatureInterface>).

```swift
// Projects/Feature/FeatureProfile/Sources/ProfileView.swift
public struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>
    public init(store: StoreOf<ProfileFeature>) { self.store = store }

    public var body: some View {
        Form {
            TextField("Display name", text: $store.profile.displayName)   // 예시
        }
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { store.send(.userTappedSaveButton) }
        }}
        .onAppear { store.send(.onAppear) }
    }
}
```

**주의** — `@Bindable var store` 표준, `WithViewStore` 금지. `SharedDesignSystem` 토큰/컴포넌트(`Color.dsPrimary`, `PrimaryButton`) 우선. View 에서 `Task { await }` 직접 만들지 말고 `store.send` 로 위임.

## Step 5 — Project.swift + umbrella + 생성

각 모듈은 레이어 팩토리만 호출한다. cross-layer 의존은 **Interface 전용 액세서**로.

```swift
// Projects/Domain/DomainProfile/Project.swift
let project = Project.makeModule(name: "DomainProfile", targets: [
    .domain(interface: "Profile", factory: .init(dependencies: [.composableArchitecture])),
    .domain(implements: "Profile", factory: .init(dependencies: [.composableArchitecture])),
    .domain(testing: "Profile"),
    .domain(tests: "Profile"),
])

// Projects/Feature/FeatureProfile/Project.swift
let project = Project.makeModule(name: "FeatureProfile", targets: [
    // Feature 는 interface 없음 (D3) — implements 부터 시작
    .feature(implements: "Profile", factory: .init(dependencies: [
        .domain(interface: .profile),   // Domain Interface 만!
        .composableArchitecture,
    ])),
    .feature(testing: "Profile"),
    .feature(tests: "Profile"),
    .feature(example: "Profile", factory: .init(dependencies: [
        .project(target: "DomainProfileImplementation", path: .domain(.profile)),  // Example 은 liveValue link
    ])),
])
```

umbrella `Project.swift` 의 dependencies 는 `ModulePath.{Layer}.allCases` 를 순회해 **자동 생성**되므로 Step 1 의 case 등록으로 충분하다. 남은 건 재노출 한 줄 — `Sources/Source.swift` 에 `@_exported import` 를 추가한다:

```swift
// Projects/Domain/Sources/Source.swift
@_exported import DomainProfileImplementation
// Projects/Feature/Sources/Source.swift
@_exported import FeatureProfileImplementation
```

```bash
tuist install && tuist generate
```

> `Modules.swift`·`Source.swift` 를 고친 뒤 `tuist generate` 를 빼먹으면 캐시된 그래프로 빌드돼 새 모듈이 누락된 채 "거짓 성공" 이 난다. 반드시 재생성.

---

## Step 6 — 호스트에 연결

### (a) 새 탭으로 추가

호스트가 ``AppFeature`` 가 된다.

```swift
// AppFeature.State
public var profile: ProfileFeature.State
// AppFeature.Tab
case home, users, activity, profile
// AppFeature.body
Scope(state: \.profile, action: \.profile) { ProfileFeature() }
```

``AppView`` 의 `TabView` 에 `.tabItem` + `.tag` 한 쌍을 추가하면 끝. (App 은 `.feature` umbrella 를 link 하므로 `ProfileFeature` 구체 타입을 안다.)

### (b) 다른 Feature 에서 진입 (cross-feature)

`Profile` 편집을 **Users 상세**에서 띄우는 경우. `UsersFeature` 는 `ProfileFeature` 를 모른다 — `delegate` 로 신호만 올리고, ``AppFeature`` 가 받아 조립한다.

```swift
// 1) UsersFeature — 신호만 위로 (ProfileFeature import 안 함)
public enum Delegate: Equatable { case editProfile(id: Int) }
case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    return .send(.delegate(.editProfile(id: id)))

// 2) AppFeature — 앱 레벨 sheet 로 제시 + 결과를 되돌려줌
@Presents public var editProfile: ProfileFeature.State?
case editProfile(PresentationAction<ProfileFeature.Action>)
case let .users(.delegate(.editProfile(id))):
    state.editProfile = ProfileFeature.State(profileId: id)
    return .none
case let .editProfile(.presented(.delegate(.profileSaved(profile)))):
    state.editProfile = nil
    return .send(.users(.profileUpdated(profile)))   // Users 가 목록/상세 갱신
.ifLet(\.$editProfile, action: \.editProfile) { ProfileFeature() }
```

```swift
// 3) AppView — sheet 로 제시
.sheet(item: $store.scope(state: \.editProfile, action: \.editProfile)) { store in
    NavigationStack { ProfileView(store: store) }
}
```

> Tip: **같은 도메인 안에** 푸시 화면을 더하는 경우(예: Users 안에 새 상세 화면)는 cross-feature 가 아니므로 그 도메인의 `Path` enum 에 case 를 추가한다. 자세한 라우팅 케이스는 <doc:NavigationPatterns>.

## See Also

- <doc:NavigationPatterns>
- <doc:FeatureInterface>
- ``AppFeature``
