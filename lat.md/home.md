# Home 도메인

홈 탭. **외부 IO 가 없는 Feature 예시** — Client 의존 없음(`Project.feature(name: "Home")`).

## 흐름
현재 standalone 화면으로 cross-feature 전환이 없다.

## 주의사항
확장할 때 따라야 할 규칙.
- 새 외부 IO 가 필요해지면 Client 모듈을 먼저 만들고(`Project.client`) Interface 만 의존. → [[clients]]
- 다른 Feature 로 전환이 생기면 직접 import 하지 말고 `delegate` → AppFeature. → [[app#Cross-feature Routing]]
