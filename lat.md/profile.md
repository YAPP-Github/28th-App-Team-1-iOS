# Profile 도메인

프로필 조회/편집 화면. 탭으로도 뜨고, Users 흐름에서 편집 sheet 로도 제시된다.

## Load → Edit → Save Flow
화면 진입부터 저장까지의 도메인 내부 데이터 흐름.
- `onAppear` → `ProfileClient#fetchProfile(id)` → `profileLoaded`
- 편집은 `editedDisplayName` / `editedBio` 바인딩.
- `userTappedSaveButton` → `ProfileClient#saveProfile` → `profileSaved`

## Save
⚠️ cross-feature 출구. 저장 성공 시 **delegate 로만** 외부에 알린다 (누가 띄웠는지 모름).
- `ProfileFeature` → `delegate(.profileSaved(Profile))`
- 코디네이터(AppFeature)가 받아 sheet 닫고 Users 에 통보. → [[app#Cross-feature Routing]]
- `@lat`: [[profile#Save]]

## 주의사항
이 도메인의 단방향성을 깨면 안 되는 불변식.
- Profile 은 자신을 띄운 화면(Users/탭)을 모른다 — delegate 만 방출. 이 단방향성이 깨지면 결합 0 원칙 위반.
- Save 후 화면 닫기/이동은 **코디네이터 책임**이지 Profile 책임이 아니다.

## 의존
이 도메인이 의존하는 외부 모듈.
- 데이터: [[clients]] (ProfileClient#fetchProfile, #saveProfile)
