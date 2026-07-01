# Home 도메인

홈 탭. **외부 IO 가 없는 Feature 예시** — Domain(Client) 의존 없이 `.composableArchitecture` 만 쓰는 단일 Feature 모듈(`FeatureHome`). 현재 골격에서 유일한 실 Feature 다.

## 흐름
현재 standalone 화면으로 cross-feature 전환이 없다. `HomeFeature`(Reducer) + `HomeView` 뿐이고 State/Action 은 비어 있는 씨앗 상태.

## 주의사항
확장할 때 따라야 할 규칙.
- Feature 는 Interface 를 두지 않는 **단일 모듈**이다(D3). Reducer/View 는 `Sources/` 에. → DocC `FeatureInterface`
- 새 외부 IO 가 필요해지면 Domain 모듈을 먼저 만들고(`Domain{Name}`) `.domain(interface:)` 만 의존한다. `liveValue` 는 App/Example 이 link.
- 다른 Feature 로 전환이 생기면 직접 import 하지 말고 `delegate` → AppFeature. → [[app#Cross-feature Routing]]
