# Reels 도메인

릴스 댓글 시트 예시 Feature. **댓글 시트가 올라오며 영상이 비율대로 축소**되는 인스타그램식 인터랙션을 보여주는 독립 Example(`FeatureReels`). 외부 IO·cross-feature 없이 `.composableArchitecture` 만 쓰는 단일 모듈이고, 모델(`Reel`/`Comment`)은 피처 내부에 자체 정의한다.

## 인터랙션 메커닉

시스템 `.sheet` 는 presenter(영상)를 축소하지 못한다. 그래서 `ZStack` 에 영상 레이어 + 커스텀 드래그 시트를 겹치고, 시트 높이 진행률(progress 0~1)을 영상의 `scaleEffect(anchor:.top)`·`offset`·`cornerRadius` 에 매핑한다. 드래그는 그랩 핸들의 `DragGesture` 로 러버밴드 클램프하고, 손을 떼면 위치·속도 기반으로 열림/닫힘 스냅한다.

## 상태 분리

초당 60~120회 갱신되는 **연속 드래그 값(sheetHeight)은 View-local `@State`**, **이산 상태만 Reducer State**(`isCommentsPresented`·`comments`·`draftComment`·`isPlaying`)에 둔다. 스토어에 고빈도 액션을 방출하지 않기 위함이다.

둘의 다리는 `ReelsView` 의 `.onChange(of: store.isCommentsPresented)` — 단일 진실원천은 `isCommentsPresented`, 연속 애니메이션은 View 가 조정한다.

## 주의사항

확장·이관할 때 따라야 할 규칙.
- cross-feature 전환 없음. 메인 탭에 붙이지 않은 독립 Example 이라 `AppFeature` 는 손대지 않는다. 탭으로 승격하려면 delegate → AppFeature. → [[app]]
- 실데이터로 승격 시 `Reel`/`Comment` 를 `DomainReels` 모듈로 분리하고 `.domain(interface:)` 만 의존한다. 현재는 예시라 로컬 정의.
- `SharedDesignSystem` 이관 전까지 스타일은 plain SwiftUI(system color/font). 토큰 생기면 교체.
- 영상 재생은 View 책임(`ReelPlayerView` 가 `isPlaying` 관찰). Reducer 는 재생 IO 를 직접 하지 않는다.
