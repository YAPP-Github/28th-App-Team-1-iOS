# 새 Feature 추가하기

푸시 가능한 새 화면 한 개를 더하는 표준 절차.

## Overview

`Profile` 화면을 예로 든다. SPM target 분리 구조라 새 화면을 추가할 때 손대는 위치는 다음과 같다.

| 단계 | 위치 |
|---|---|
| 1 | `Sources/Models/Profile.swift` (필요 시) |
| 2 | `Sources/ProfileClient/ProfileClient.swift` (외부 접근이 필요할 때만) |
| 3 | `Sources/ProfileFeature/ProfileFeature.swift` |
| 4 | `Sources/ProfileFeature/ProfileView.swift` |
| 5 | 호스트 Feature 의 `Path` enum + destination switch (예: ``UserFeature``) |
| 6 | `ArchitecturePackage/Package.swift` — 새 target 등록 + 의존 관계 |

> Note: 화면을 어디에 붙일지에 따라 Step 5 의 호스트가 달라진다. 기존 도메인의 스택에 끼우면
> 그 도메인 Feature (예: ``UserFeature``) 가 호스트, 완전히 새 탭이면 ``AppFeature`` 가 호스트가 된다.
> "새 탭으로 추가" 시나리오는 맨 아래에서 따로 다룬다.

---

## Step 1 — Domain 모델

```swift
// Sources/Models/Profile.swift
public struct Profile: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public var displayName: String
    public var bio: String
    public var location: String?
}
```

**언제 쓰는가** — 기존 `User` 와 책임이 분리되는 표현이 필요할 때. 같은 데이터의 다른 단면이거나 편집 전용 모델.
**어떻게 쓰는가** — `struct + Equatable + Identifiable + Sendable` 4종 세트가 기본. Reducer State 에 들어가려면 `Equatable` 필수.
**주의할 점** — `Sendable` 을 빼면 `@Dependency` 클로저에 넣을 때 Swift 6 모드에서 경고가 뜬다. SPM target 경계를 넘는 타입은 반드시 `public`.

## Step 2 — Dependency (Repository)

```swift
// Sources/ProfileClient/ProfileClient.swift
public struct ProfileClient: Sendable {
    public var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    public var saveProfile: @Sendable (_ profile: Profile) async throws -> Profile
}

extension ProfileClient: DependencyKey {
    public static let liveValue  = ProfileClient(fetchProfile: { ... }, saveProfile: { ... })
    public static let previewValue = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    public static let testValue  = ProfileClient(
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

**언제 쓰는가** — 화면이 네트워크/디스크/시계/UUID 같은 외부 자원에 의존할 때마다.
**어떻게 쓰는가** — 클로저 프로퍼티만 가진 `struct` + 세 가지 값(`liveValue`/`previewValue`/`testValue`) + `DependencyValues` 슬롯. 이 네 줄짜리 규칙이 곧 컨벤션이다.
**주의할 점** — `testValue` 는 반드시 `unimplemented` 또는 `XCTFail` 동등물을 사용하라. 빈 클로저로 두면 테스트가 의도치 않게 통과한다.

## Step 3 — Reducer

```swift
// Sources/ProfileFeature/ProfileFeature.swift
@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        public let profileId: Int
        public var profile: Profile?
        public var isLoading = false
        public var isSaving = false
        public var errorMessage: String?
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
            case profileSaved(Profile)
        }
    }

    @Dependency(\.profileClient) var profileClient

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            // ...
        }
    }
}
```

**언제 쓰는가** — 모든 화면. 액션 enum 의 case 네이밍 규칙(`userTapped...`, `...Loaded`, `onAppear`)을 일관되게 지킨다.
**어떻게 쓰는가** — 폼 입력이 있으면 `BindableAction` + `BindingReducer`. 부모로 결과를 돌려보낼 때는 `delegate(Delegate)` case 를 추가.
**주의할 점** — `@Reducer` 안의 State 가 다른 Reducer 의 자식으로 들어가는 한, 반드시 `Equatable` 이어야 한다. 모든 public API 에 `public` 키워드 빼먹지 말 것.

## Step 4 — View

```swift
// Sources/ProfileFeature/ProfileView.swift
public struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    public init(store: StoreOf<ProfileFeature>) { self.store = store }

    public var body: some View {
        Form {
            TextField("Display name", text: $store.editedDisplayName)
            TextField("Bio", text: $store.editedBio, axis: .vertical)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { store.send(.userTappedSaveButton) }
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
```

**언제 쓰는가** — 모든 화면. `@Bindable var store` 패턴이 표준.
**어떻게 쓰는가** — 폼 양방향 바인딩은 `$store.fieldName`. 단방향 액션은 `store.send(.someAction)`. ``DesignSystemKit`` 의 토큰/컴포넌트 (예: `Color.dsPrimary`, `PrimaryButton`) 를 우선 사용.
**주의할 점** — `WithViewStore` 는 사용 금지. 또 `Task { ... await ... }` 를 View 에서 직접 만들지 말고 항상 `store.send` 로 위임할 것.

## Step 5 — Path 등록 + destination switch

기존 도메인의 스택에 끼우는 경우 — 예시는 ``UserFeature``.

```swift
// Sources/UserFeature/UserFeature.swift
@Reducer
public enum Path {
    case detail(UserDetailFeature)
    case profile(ProfileFeature)   // ← 추가
}
```

``UserFeature`` 의 `body` 안에서 어떻게 push 할지 한 줄.

```swift
case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    state.path.append(.profile(ProfileFeature.State(profileId: id)))
    return .none
```

``UserFeatureView`` 의 `destination` switch 에 한 줄.

```swift
case let .profile(profileStore):
    ProfileView(store: profileStore)
```

## Step 6 — Package.swift 에 새 target 등록

```swift
// ArchitecturePackage/Package.swift
.target(
    name: "ProfileFeature",
    dependencies: [
        "Models",
        "ProfileClient",
        "DesignSystemKit",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
    ]
),
```

그리고 호스트 Feature 의 dependency 에도 추가:

```swift
.target(
    name: "UserFeature",
    dependencies: [
        "Models", "UserClient", "ProfileFeature", "DesignSystemKit",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
    ]
),
```

이 시점에서 시뮬레이터를 다시 돌리면 새 화면이 그대로 동작한다.

---

## 새 탭으로 추가하는 경우

기존 도메인 스택에 끼우는 대신 완전히 새 탭으로 띄울 때는 호스트가 ``AppFeature`` 가 된다.
`Home`, `Activity` 탭이 만들어진 절차와 같다.

```swift
// Sources/AppFeature/AppFeature.swift
public struct State: Equatable {
    public var home: HomeFeature.State
    public var users: UserFeature.State
    public var activity: ActivityFeature.State
    public var profile: ProfileFeature.State
    public var newTab: NewTabFeature.State   // ← 추가
}

public enum Tab: String, Equatable {
    case home, users, activity, profile
    case newTab                              // ← 추가
}

public var body: some ReducerOf<Self> {
    // ...
    Scope(state: \.newTab, action: \.newTab) {
        NewTabFeature()
    }
}
```

``AppView`` 의 `TabView` 에 `.tabItem` + `.tag` 한 쌍을 추가하면 끝. 이 경우 Step 5 의
호스트 Feature path 작업은 생략된다 (탭 안에서 더 push 할 화면이 없다면).

## See Also

- <doc:NavigationPatterns>
- <doc:AddingFeatureTutorial>
- ``AppFeature``
- ``UserFeature``
