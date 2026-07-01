# Architecture — 지식 그래프 인덱스

이 프로젝트(SwiftUI + TCA · Tuist TMA)의 도메인 지식·설계 의도·cross-feature 숨은 의존을 정의하는 lat.md 노드 목록.

- [[architecture]] — 시스템 총론·레이어·핵심 결정(D1~D3)
- [[domain.map]] — 도메인 간 관계도·cross-feature 숨은 의존
- [[app]] — AppFeature 코디네이터·cross-feature 라우팅
- [[home]] — Home 도메인 (현재 유일한 실 Feature)
- [[reels]] — 릴스 댓글 시트(영상 비율 축소) 예시 Feature

> `refactor/#6` 은 TMA 스켈레톤 단계다. 실 Feature 노드는 [[home]], 인터랙션 예시로 [[reels]] 가 있다. Users·Profile 등은 이관되면서 노드가 추가된다.

방법론·라벨링 규칙은 그래프 밖 문서로 분리되어 있다: [lat-methodology](../docs/lat-methodology.md) · [lat-labeling](../docs/lat-labeling.md).
