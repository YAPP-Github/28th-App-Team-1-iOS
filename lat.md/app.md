# App 도메인 — 코디네이터 (AppFeature)

앱 최상위 Reducer 겸 **탭 코디네이터**. 각 탭 Feature 의 State 를 보유하고, **Feature 간(cross-feature) 전환은 여기서만** 조립한다. 각 Feature 는 서로를 모르고 `delegate` 로만 신호를 올린다. (현재 #6 은 스켈레톤 — AppFeature 는 골격이고 탭은 이관되며 채워진다.)

## 탭 구성
`Scope` 로 각 Feature 를 상시 임베드한다. App 은 `.feature` umbrella 를 link 하므로 자식 reducer 를 구체 타입으로 안다. 탭끼리는 서로를 모른다.
- 예정 탭 여럿 중 현재 실 Feature 는 Home 뿐. → [[home]]
- 각 Feature 의 **도메인 내부** navigation 은 그 Feature 가 자체 처리(`Path`/`StackState`). AppFeature 는 관여하지 않는다.

## Cross-feature Routing
다른 Feature 로 넘어가는 전환의 **유일한 조립 지점**. leaf 가 직접 못 하고 코디네이터를 경유하는 이유 → DocC `FeatureInterface`, [[architecture]] D1·D3.

대표 흐름 — **Users 상세 → 프로필 편집** (둘은 서로 import 하지 않는다):
1. `UsersFeature` 가 `delegate(.editProfile(id))` 방출 → AppFeature 수신
2. 앱 레벨 sheet 로 Profile 제시: `state.editProfile = ProfileFeature.State(profileId: id)` (`@Presents` + `.ifLet`)
3. 저장 완료 `editProfile(.presented(.delegate(.profileSaved(profile))))` → sheet 닫고 `users(.profileUpdated(profile))` 로 결과 통보

→ 큰 그림은 [[domain.map]].

## 주의사항
코디네이터 패턴을 유지하기 위한 규칙.
- **Feature → Feature 의존 0.** 새 cross-feature 전환이 생기면 leaf Feature 엔 `delegate` case 만 추가하고, 조립(State 생성·제시·결과 통보)은 전부 여기서 한다. 직접 import/push 금지.
- 다른 Feature 의 reducer/State 를 구체 타입으로 참조해도 되는 **유일한 자리**(owner/코디네이터). leaf 끼리는 금지.
- 새 탭은 `State` / `Tab` / body `Scope` + `AppView` 의 `TabView` 에 추가. → DocC `AddingFeature`
