# Users 도메인

사용자 List → Detail 흐름 컨테이너. `UsersFeature` 가 자체 `StackState` 로 도메인 내 네비를 관리.

## List → Detail
`UserListFeature` 행 탭(`delegate.userTappedRow`) → `path.append(.detail(...))`.

## Profile Edit Handoff  ⚠️ cross-feature
상세 화면의 "편집" 버튼은 Profile 을 직접 열지 않는다 — delegate 로 위로 올린다.
- `UserDetailFeature` → `delegate(.editProfileTapped(id))`
- `UsersFeature` → `delegate(.editProfile(id))` (코디네이터가 수신)
- 저장 결과는 `profileUpdated(Profile)` 로 되돌려받아 list/열린 detail 에 반영.
- `@lat`: [[users#Profile Edit Handoff]] · depends-on [[profile#Save]] · [[app#Cross-feature Routing]]

## 주의사항
- Users 는 **ProfileFeature 를 import 하지 않는다.** Profile 의 State/Action 을 알지 못한다.
- 따라서 Profile 의 `Profile` 모델 필드가 바뀌면 `applyProfileUpdate` 동기화 로직을 같이 봐야 한다.

## 의존
- 데이터: [[clients]] (UserClient#fetchUser)
