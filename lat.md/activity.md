# Activity 도메인

활동(알림/피드) 탭.

## 흐름
활동 데이터를 Client 로 조회하는 단순 화면.
- 데이터: [[clients]] (ActivityClient)

## 주의사항
확장할 때 따라야 할 규칙.
- cross-feature 전환은 delegate → AppFeature 경유. → [[app#Cross-feature Routing]]
