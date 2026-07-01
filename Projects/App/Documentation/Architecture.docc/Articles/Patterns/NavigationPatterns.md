# 화면 간 값 전달 패턴

상황에 따라 골라 쓰는 패턴 — 그리고 **도메인 내부 navigation 과 cross-feature 전환의 경계**.

## Overview

먼저 큰 두 갈래를 구분한다.

- **도메인 내부 navigation** — 한 Feature 안의 화면 스택. 그 Feature 가 자체 `Path` enum + `StackState` 로 직접 push/pop 한다. (예: Users 의 목록→상세)
- **Cross-feature 전환** — 다른 Feature 로 넘어가는 것. **직접 하지 않는다.** `delegate` 로 ``AppFeature`` 에 신호를 올리고, 코디네이터가 조립한다. (예: Users 상세 → 프로필 편집) — Feature→Feature 의존 0.

값 전달 자체는 거의 모든 경우 다음 셋 중 하나다.

| 케이스 | 무엇을 넘기는가 | 누가 fetch | 본 프로젝트 예시 |
|---|---|---|---|
| A | id 만 | 자식이 직접 | ``AppFeature`` → ``ProfileFeature``(`profileId`) |
| B | 객체 전체 | 부모가 이미 보유 | `UserListFeature` → `UserDetailFeature` |
| C | 결과를 위로 | 자식이 부모에 통보 | `ProfileFeature` → ``AppFeature`` → `UsersFeature` |

---

## Case A — id 만 전달 → 화면에서 fetch

```swift
// 제시하는 쪽 (AppFeature) — id 만 담아 State 생성
case let .users(.delegate(.editProfile(id))):
    state.editProfile = ProfileFeature.State(profileId: id)
    return .none

// 자식 (ProfileFeature) — onAppear 에서 fetch
case .onAppear:
    return .run { [id = state.profileId] send in
        let profile = try await profileClient.fetchProfile(id)
        await send(.profileLoaded(profile))
    }
    .cancellable(id: CancelID.load)
```

**언제** — 부모가 가진 데이터가 부족하거나 항상 최신본이 필요할 때(편집 화면).
**어떻게** — 자식 `State` 에 `let id` + `init(id:)` 만 노출, 나머지는 옵셔널/기본값. `onAppear` fetch.
**주의** — 진입 직후 빈 껍데기가 보이므로 `isLoading` 분기 필수. `onDisappear` 에서 `.cancel(id:)` 로 in-flight 요청을 끊을 것 — dismiss 후 응답이 도착하면 알 수 없는 상태가 된다.

## Case B — 객체 직접 전달 → 즉시 표시 (도메인 내부)

```swift
// 상위 (UsersFeature) — 자체 Path 스택에 push
case let .list(.delegate(.userTappedRow(user))):
    state.path.append(.detail(UserDetailFeature.State(user: user)))
    return .none

// 자식 (UserDetailFeature)
public struct State: Equatable {
    public var user: User     // 진입 즉시 표시 가능
    public var isLoading = false
}
```

**언제** — 부모가 이미 가진 데이터로 충분하거나, 깜빡임 없이 보여야 할 때(목록→상세).
**어떻게** — `init(user:)` 로 객체 통째 전달. 같은 도메인 안이라 `UsersFeature.Path` 에 그대로 push.
**주의** — 부모가 든 객체가 stale 일 수 있다 → 편집 결과 반영은 Case C 와 짝지어 쓴다.

## Case C — 결과를 위로 (delegate)

delegate 는 **"사실 통보"** 다(자식이 부모에 명령하는 통로가 아님). 그래서 과거형 이름(`profileSaved`, `editProfileTapped`)을 쓴다. 두 방향이 있다:

```swift
// 자식 (ProfileFeature) — 저장 결과 통보
case let .profileSaved(profile):
    state.isSaving = false
    return .send(.delegate(.profileSaved(profile)))

// 코디네이터 (AppFeature) — sheet 닫고 결과를 도메인에 전달
case let .editProfile(.presented(.delegate(.profileSaved(profile)))):
    state.editProfile = nil
    return .send(.users(.profileUpdated(profile)))

// 도메인 (UsersFeature) — 목록 + 열린 상세 양쪽 갱신
case let .profileUpdated(profile):
    applyProfileUpdate(profile, to: &state)   // list & path 의 detail 동기화
    return .none
```

**언제** — 자식 결과가 부모/형제 화면에 반영돼야 할 때(편집·선택).
**어떻게** — 자식 Action 에 `delegate(Delegate)` 를 별도 enum 으로 분리. 받는 쪽이 dismiss·갱신·후속 작업을 책임진다.
**주의** — cross-feature 일 때 결과를 받는 건 **코디네이터(AppFeature)** 다. 도메인끼리 직접 주고받지 않는다.

---

## Cross-feature 전환은 어떻게 흐르나

Users 상세의 "편집"은 다른 Feature(`ProfileFeature`)다. `UsersFeature` 는 `ProfileFeature` 를 **import 하지 않는다.** 신호가 delegate 로 위까지 올라갔다가, `AppFeature` 가 sheet 로 제시하고 결과를 되돌린다.

```text
UserDetailFeature  delegate(.editProfileTapped(id))
        │
        ▼
UsersFeature       delegate(.editProfile(id))          ← 그대로 위로 bubble
        │
        ▼
AppFeature         state.editProfile = .init(id)  →  sheet 로 ProfileFeature 제시
        ▲
        │          delegate(.profileSaved) ◀── ProfileFeature (저장)
        ▼
AppFeature         .send(.users(.profileUpdated))  →  UsersFeature 가 목록/상세 갱신
```

핵심: **각 Feature 는 "위(부모)" 만 안다.** `UsersFeature` 는 `ProfileFeature` 의 존재를 모르고, 오직 자기 `delegate` 만 방출한다. 조립 지점은 `AppFeature` 단 한 곳.

## 왜 도메인이 자체 Path 를 들고 있나

탭이 도입되면서, user 화면 스택은 **Users 탭 안에서만** 의미가 있으므로 그 책임을 `UsersFeature` 로 두었다.

- 탭을 가로지르는 navigation 이 구조적으로 차단됨
- ``AppFeature`` 는 탭 보유 + cross-feature 라우팅에만 집중
- 새 탭 추가 시 기존 도메인 navigation 코드를 건드릴 일 없음

새 도메인도 같은 패턴: 도메인 안에 여러 화면이 있으면 그 Feature 가 자체 `Path` + `StackState` 를 들고, ``AppFeature`` 는 그 Feature.State 만 보유한다. 다른 도메인으로 넘어갈 때만 `delegate` 로 올린다.

## 관련 심볼

- ``AppFeature`` — 탭 + cross-feature 코디네이터
- ``UsersFeature`` — Users 도메인의 Path 코디네이터 + delegate bubble
- `UserListFeature.Action.Delegate` — Case B 트리거
- `UserDetailFeature.Action.Delegate` — cross-feature 신호의 출발점
- `ProfileFeature.Action.Delegate` — Case C 발신 (AppFeature 가 수신)

## Topics

### 함께 보기

- <doc:AddingFeature>
- <doc:FeatureInterface>
