# 화면 간 값 전달 패턴

상황에 따라 골라 쓰는 세 가지 패턴.

## Overview

TCA 에서 화면 사이에 데이터를 옮길 때 거의 모든 경우는 다음 셋 중 하나다.

| 케이스 | 무엇을 넘기는가 | 누가 fetch 하는가 | 본 프로젝트의 예시 |
|---|---|---|---|
| A | id 만 | 자식이 직접 | `UserDetailFeature` → `ProfileFeature` |
| B | 객체 전체 | 부모가 이미 들고 있음 | `UserListFeature` → `UserDetailFeature` |
| C | 결과를 위로 | 자식이 부모에게 알림 | `ProfileFeature` → ``AppFeature`` |

세 케이스 모두 본 앱 안에서 실제로 동작하는 흐름이다. 한 번 실행해 보면서 비교하면 가장 빠르다.

---

## Case A — id 만 전달 → 화면에서 fetch

```swift
// 상위 (AppFeature)
case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
    state.path.append(.profile(ProfileFeature.State(profileId: id)))
    return .none

// 자식 (ProfileFeature)
case .onAppear:
    return .run { [id = state.profileId] send in
        let profile = try await profileClient.fetchProfile(id)
        await send(.profileLoaded(profile))
    }
```

**언제 쓰는가** — 부모 화면이 들고 있는 데이터가 자식 화면에 부족할 때, 또는 항상 최신본을 받아야 할 때 (편집 화면, 캐시 무효화).
**어떻게 쓰는가** — 자식 `State` 에 `let id: Int` 를 두고 `init(id:)` 하나만 노출. 나머지 필드는 모두 옵셔널/기본값. `onAppear` 에서 fetch.
**주의할 점** — 진입 직후 빈 껍데기를 보여주게 되므로 `isLoading` 분기를 반드시 둔다. 그리고 `onDisappear` 에서 `.cancel(id:)` 로 in-flight 요청을 끊을 것 — pop 후에도 응답이 오면 reducer 에 액션이 도착해 알 수 없는 상태가 된다.

## Case B — 객체 직접 전달 → 추가 fetch 없이 즉시 표시

```swift
// 상위 (AppFeature)
case let .userList(.delegate(.userTappedRow(user))):
    state.path.append(.detail(UserDetailFeature.State(user: user)))
    return .none

// 자식 (UserDetailFeature)
struct State: Equatable {
    var user: User       // 진입 즉시 표시 가능
    var isLoading = false
}
```

**언제 쓰는가** — 부모가 이미 갖고 있는 데이터로 충분하거나, 사용자가 진입 직후 깜빡임 없이 보길 원할 때 (목록→상세, 채팅 목록→채팅방의 헤더).
**어떻게 쓰는가** — `init(user:)` 에 객체 통째를 받는다. 자식이 detail 전용 데이터(bio 등)만 따로 fetch 하는 변형도 자연스럽다.
**주의할 점** — 부모가 들고 있는 객체가 stale 일 수 있다. 편집 결과를 반영하려면 반드시 Case C 와 짝지어 쓴다. 또 객체가 크면 메모리 압박이 있을 수 있는데, 그땐 Case A 로 전환.

## Case C — 하위 → 상위 결과 반환 (delegate 패턴)

```swift
// 자식 (ProfileFeature)
enum Action {
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
        case profileSaved(Profile)
    }
}

case let .profileSaved(profile):
    state.isSaving = false
    return .send(.delegate(.profileSaved(profile)))   // 부모에 통보

// 상위 (AppFeature)
case let .path(.element(id: _, action: .profile(.delegate(.profileSaved(profile))))):
    // 목록과 스택에 남아 있는 상세 양쪽을 갱신
    if let i = state.userList.users.firstIndex(where: { $0.id == profile.id }) {
        state.userList.users[i].name = profile.displayName
        state.userList.users[i].bio = profile.bio
    }
    for id in state.path.ids {
        guard case .detail(var detail) = state.path[id: id],
              detail.user.id == profile.id else { continue }
        detail.user.name = profile.displayName
        detail.user.bio = profile.bio
        state.path[id: id] = .detail(detail)
    }
    state.path.removeLast()
    return .none
```

**언제 쓰는가** — 자식 화면에서 만든 결과가 부모/형제 화면에 반영되어야 할 때 (편집·저장·선택 화면).
**어떻게 쓰는가** — 자식 Action 에 `delegate(Delegate)` 케이스를 별도 enum 으로 분리한다. 부모는 `case let .path(.element(id: _, action: .child(.delegate(...))))` 한 줄로 받는다. pop / 추가 작업 / 형제 갱신 모두 부모 책임.
**주의할 점** — delegate 는 "사실 통보" 다. 자식이 부모의 명령을 내리는 통로가 아니다. 행동 동사가 아니라 과거형(`profileSaved`, `itemSelected`) 을 쓰는 이유. 그리고 delegate 만 발사하고 자기 State 는 안 만지면, pop 직후 화면이 갑자기 비어 보일 수 있어 그 직전에 `state.isSaving = false` 같은 정리를 잊지 말 것.

## 관련 심볼

본 프로젝트에서 위 패턴을 구현하는 핵심 타입:

- ``AppFeature`` — Coordinator + delegate 라우팅
- `AppFeature.Path` — 푸시 가능한 화면 enum
- `UserListFeature.Action.Delegate` — Case B 트리거
- `UserDetailFeature.Action.Delegate` — Case A 트리거
- `ProfileFeature.Action.Delegate` — Case C 발신

## Topics

### 함께 보기

- <doc:AddingFeature>
- <doc:NavigationPatternsTutorial>
