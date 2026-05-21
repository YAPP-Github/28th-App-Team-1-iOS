# 새 Feature 추가하기

푸시 가능한 새 화면 한 개를 더하는 표준 절차.

## Overview

`Profile` 화면을 예로 든다. 새 화면을 추가할 때 손대는 파일은 정확히 다음 다섯 군데뿐이다.

| 단계 | 파일 |
|---|---|
| 1 | `Domain/Profile.swift` (필요 시) |
| 2 | `Dependencies/ProfileClient.swift` (외부 접근이 필요할 때만) |
| 3 | `Features/Profile/ProfileFeature.swift` |
| 4 | `Features/Profile/ProfileView.swift` |
| 5 | `App/AppFeature.swift` + `App/ArchitectureApp.swift` (Path enum + destination switch) |

---

## Step 1 — Domain 모델

```swift
struct Profile: Equatable, Identifiable, Codable, Sendable {
    let id: Int
    var displayName: String
    var bio: String
    var location: String?
}
```

**언제 쓰는가** — 기존 ``User`` 와 책임이 분리되는 표현이 필요할 때. 같은 데이터의 다른 단면이거나 편집 전용 모델.
**어떻게 쓰는가** — `struct + Equatable + Identifiable + Sendable` 4종 세트가 기본. Reducer State 에 들어가려면 `Equatable` 필수.
**주의할 점** — `Sendable` 을 빼면 `@Dependency` 클로저에 넣을 때 Swift 6 모드에서 경고가 뜬다.

## Step 2 — Dependency (Repository)

```swift
struct ProfileClient: Sendable {
    var fetchProfile: @Sendable (_ id: Int) async throws -> Profile
    var saveProfile: @Sendable (_ profile: Profile) async throws -> Profile
}

extension ProfileClient: DependencyKey {
    static let liveValue  = ProfileClient(fetchProfile: { ... }, saveProfile: { ... })
    static let previewValue = ProfileClient(fetchProfile: { _ in .stub }, saveProfile: { $0 })
    static let testValue  = ProfileClient(
        fetchProfile: unimplemented("ProfileClient.fetchProfile", placeholder: .stub),
        saveProfile:  unimplemented("ProfileClient.saveProfile",  placeholder: .stub)
    )
}

extension DependencyValues {
    var profileClient: ProfileClient {
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
@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        let profileId: Int
        var profile: Profile?
        var isLoading = false
        var isSaving = false
        var errorMessage: String?
        var editedDisplayName = ""
        var editedBio = ""

        init(profileId: Int) { self.profileId = profileId }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case userTappedSaveButton
        case profileLoaded(Profile)
        case profileSaved(Profile)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case profileSaved(Profile)
        }
    }

    @Dependency(\.profileClient) var profileClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            // ...
        }
    }
}
```

**언제 쓰는가** — 모든 화면. 액션 enum 의 case 네이밍 규칙(`userTapped...`, `...Loaded`, `onAppear`)을 일관되게 지킨다.
**어떻게 쓰는가** — 폼 입력이 있으면 `BindableAction` + `BindingReducer`. 부모로 결과를 돌려보낼 때는 `delegate(Delegate)` case 를 추가.
**주의할 점** — `@Reducer` 안의 State 가 다른 Reducer 의 자식으로 들어가는 한, 반드시 `Equatable` 이어야 한다.

## Step 4 — View

```swift
struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
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
**어떻게 쓰는가** — 폼 양방향 바인딩은 `$store.fieldName`. 단방향 액션은 `store.send(.someAction)`.
**주의할 점** — `WithViewStore` 는 사용 금지. 또 `Task { ... await ... }` 를 View 에서 직접 만들지 말고 항상 `store.send` 로 위임할 것.

## Step 5 — Path 등록 + destination switch

``AppFeature/Path-swift.enum`` 에 한 줄.

```swift
@Reducer
enum Path {
    case detail(UserDetailFeature)
    case profile(ProfileFeature)   // ← 추가
}
```

``AppFeature`` 의 `body` 안에서 어떻게 push 할지 한 줄.

```swift
case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    state.path.append(.profile(ProfileFeature.State(profileId: id)))
    return .none
```

``AppView`` 의 `destination` switch 에 한 줄.

```swift
case let .profile(profileStore):
    ProfileView(store: profileStore)
```

이 시점에서 시뮬레이터를 다시 돌리면 새 화면이 그대로 동작한다.

## See Also

- <doc:NavigationPatterns>
- <doc:AddingFeatureTutorial>
- ``AppFeature``
- ``ProfileFeature``
