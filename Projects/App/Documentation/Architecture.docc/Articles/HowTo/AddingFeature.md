# 새 Feature 추가하기

새 화면 도메인(Feature 모듈)을 더하는 표준 절차.

## Overview

`Profile` 화면을 예로 든다. Tuist µFeature 구조라 새 Feature 는 **독립 모듈**로 추가하고, 손대는 위치는 다음과 같다.

| 단계 | 위치 |
|---|---|
| 1 | `Projects/Shared/Models/Sources/Profile.swift` (필요 시) |
| 2 | `Projects/Client/ProfileClient/{Interface,Live}/` (외부 IO 가 필요할 때만) |
| 3 | `Projects/Feature/Profile/Sources/ProfileFeature.swift` |
| 4 | `Projects/Feature/Profile/Sources/ProfileView.swift` |
| 5 | `Project.swift` 작성 + `TargetDependency+Module.swift` 에 타입드 액세서 → `tuist generate` |
| 6 | 호스트에 연결 — **새 탭**이면 ``AppFeature``, **다른 Feature 에서 진입**이면 `delegate` → ``AppFeature`` 가 제시 |

> Important: 화면이 다른 Feature 라면 그 Feature 를 직접 import/push 하지 않는다. **Feature → Feature 의존은 0** 이고, cross-feature 조립은 ``AppFeature`` 에서만 한다. (Step 6 참조)

---

## Step 1 — Domain 모델

```swift
// Projects/Shared/Models/Sources/Profile.swift
public struct Profile: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public var displayName: String
    public var bio: String
    public var location: String?

    public init(id: Int, displayName: String, bio: String, location: String? = nil) { ... }
}
```

**주의** — 모듈 경계를 넘는 타입은 전부 `public`(`init` 포함). `Sendable` 을 빼면 `@Dependency` 클로저에서 Swift 6 경고. Reducer State 에 들어가려면 `Equatable` 필수.

## Step 2 — Client (Repository, Interface / Live 분리)

Client 만 Interface 와 Live 를 **별도 모듈**로 나눈다. Feature 는 Interface 만 의존하고, Live 는 App/Example 만 link 한다.

```swift
// Projects/Client/ProfileClient/Interface/ProfileClient.swift
public struct ProfileClient: Sendable {
    public var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    public var saveProfile:  @Sendable (_ profile: Profile) async throws -> Profile
    public init(...) { ... }
}

// 인터페이스에는 test/preview 값만. (liveValue 는 Live 모듈에)
extension ProfileClient: TestDependencyKey {
    public static let previewValue = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    public static let testValue = ProfileClient(
        fetchProfile: unimplemented("ProfileClient.fetchProfile", placeholder: .stub),
        saveProfile:  unimplemented("ProfileClient.saveProfile",  placeholder: .stub)
    )
}

extension DependencyValues {
    public var profileClient: ProfileClient {
        get { self[ProfileClient.self] }
        set { self[ProfileClient.self] = newValue }
    }
}
```

```swift
// Projects/Client/ProfileClient/Live/ProfileClient+Live.swift
extension ProfileClient: DependencyKey {
    public static let liveValue = ProfileClient(fetchProfile: { ... }, saveProfile: { ... })
}
```

**주의** — `testValue` 는 반드시 `unimplemented`(빈 클로저 금지). `liveValue` 는 Live 에만 두므로, App/Example 이 `*ClientLive` 를 link 해야 런타임에 활성화된다.

## Step 3 — Reducer

```swift
// Projects/Feature/Profile/Sources/ProfileFeature.swift
import ComposableArchitecture
import Models
import ProfileClientInterface

@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        public let profileId: Int
        public var profile: Profile?
        public var isLoading = false
        public var isSaving = false
        public var editedDisplayName = ""
        public var editedBio = ""
        public init(profileId: Int) { self.profileId = profileId }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case userTappedSaveButton
        case profileLoaded(Profile)
        case profileSaved(Profile)
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
        Reduce { state, action in /* ... */ }
    }
}
```

**주의** — Action 네이밍 컨벤션: 입력 `userTapped...`, 응답 `...Loaded`/`...Saved`, 생명주기 `onAppear`/`onDisappear`, 상위 통보 `delegate(Delegate)`. 다른 Feature 로의 전환은 여기서 직접 하지 말고 `delegate` 로만 신호한다.

## Step 4 — View

```swift
// Projects/Feature/Profile/Sources/ProfileView.swift
public struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>
    public init(store: StoreOf<ProfileFeature>) { self.store = store }

    public var body: some View {
        Form {
            TextField("Display name", text: $store.editedDisplayName)
            TextField("Bio", text: $store.editedBio, axis: .vertical)
        }
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { store.send(.userTappedSaveButton) }
        }}
        .onAppear { store.send(.onAppear) }
    }
}
```

**주의** — `@Bindable var store` 표준, `WithViewStore` 금지. `DesignSystemKit` 토큰/컴포넌트(`Color.dsPrimary`, `PrimaryButton`) 우선. View 에서 `Task { await }` 직접 만들지 말고 `store.send` 로 위임.

## Step 5 — Project.swift + 의존 액세서 + 생성

각 모듈은 자체 `Project.swift` 를 갖는다 — 헬퍼 호출 ~5줄뿐, target 을 직접 나열하지 않는다.

```swift
// Projects/Client/ProfileClient/Project.swift
let project = Project.client(name: "ProfileClient")

// Projects/Feature/Profile/Project.swift
let project = Project.feature(
    name: "Profile",
    dependencies: [.clientInterface("Profile"), .models],   // Interface 만!
    exampleDependencies: [.clientLive("Profile")]            // Example 은 Live link
)
```

의존 액세서(`.clientInterface` / `.feature` 등)가 없으면 헬퍼에 추가:

```swift
// Tuist/ProjectDescriptionHelpers/TargetDependency+Module.swift
static func feature(_ name: String) -> TargetDependency {
    .project(target: "\(name)Feature", path: .relativeToRoot("Projects/Feature/\(name)"))
}
```

그리고 `tuist generate`. (Package.swift 에 target 을 등록하던 단일 패키지 시절 방식은 더 이상 쓰지 않는다 — 외부 의존만 `Tuist/Package.swift` 에 있다.)

```bash
tuist install && tuist generate
```

---

## Step 6 — 호스트에 연결

### (a) 새 탭으로 추가

호스트가 ``AppFeature`` 가 된다 (Home/Activity 탭이 만들어진 방식).

```swift
// AppFeature.State
public var profile: ProfileFeature.State
// AppFeature.Tab
case home, users, activity, profile
// AppFeature.body
Scope(state: \.profile, action: \.profile) { ProfileFeature() }
```

``AppView`` 의 `TabView` 에 `.tabItem` + `.tag` 한 쌍을 추가하면 끝.

### (b) 다른 Feature 에서 진입 (cross-feature)

`Profile` 편집을 **Users 상세**에서 띄우는 경우. ``UsersFeature`` 는 ``ProfileFeature`` 를 모른다 — `delegate` 로 신호만 올리고, ``AppFeature`` 가 받아 조립한다.

```swift
// 1) UsersFeature — 신호만 위로 (ProfileFeature import 안 함)
public enum Delegate: Equatable { case editProfile(id: Int) }
// ... UserDetail 의 editProfileTapped 를 받아:
case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    return .send(.delegate(.editProfile(id: id)))

// 2) AppFeature — 앱 레벨 sheet 로 제시 + 결과를 되돌려줌
@Presents public var editProfile: ProfileFeature.State?
case editProfile(PresentationAction<ProfileFeature.Action>)
// body:
case let .users(.delegate(.editProfile(id))):
    state.editProfile = ProfileFeature.State(profileId: id)
    return .none
case let .editProfile(.presented(.delegate(.profileSaved(profile)))):
    state.editProfile = nil
    return .send(.users(.profileUpdated(profile)))   // Users 가 목록/상세 갱신
// ...
.ifLet(\.$editProfile, action: \.editProfile) { ProfileFeature() }
```

```swift
// 3) AppView — sheet 로 제시
.sheet(item: $store.scope(state: \.editProfile, action: \.editProfile)) { store in
    NavigationStack { ProfileView(store: store) }
}
```

> Tip: **같은 도메인 안에** 푸시 화면을 더하는 경우(예: Users 안에 새 상세 화면)는 cross-feature 가 아니므로 그 도메인의 `Path` enum 에 case 를 추가하면 된다. 자세한 라우팅 케이스는 <doc:NavigationPatterns>.

## See Also

- <doc:NavigationPatterns>
- <doc:AddingFeatureTutorial>
- ``AppFeature``
- ``UsersFeature``
