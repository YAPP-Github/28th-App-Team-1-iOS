# Architecture — 지식 그래프 인덱스

이 프로젝트(SwiftUI + TCA · Tuist TMA)의 도메인 지식·설계 의도·cross-feature 숨은 의존을 정의하는 lat.md 노드 목록.

- [[architecture]] — 시스템 총론·레이어·핵심 결정(D1~D3)
- [[domain.map]] — 도메인 간 관계도·cross-feature 숨은 의존
- [[api]] — D14 서버 API ↔ Domain Client 매핑·공통 규약(envelope·토큰·폴링·스트리밍)
- [[app]] — AppFeature 코디네이터·cross-feature 라우팅
- [[home]] — Home 도메인 (현재 유일한 실 Feature)
- [[auth]] — Auth 도메인 (카카오·애플 소셜 로그인 + 서버 세션 교환)
- [[interview]] — Interview 도메인 (InterviewClient — 면접 세션 API)
- [[feedback]] — Feedback 도메인 (G4 게스트 평가 — 무인증 토큰 진입·태도 척도 제출)

> `refactor/#6` 은 TMA 스켈레톤 단계라 실 Feature 노드는 [[home]] 뿐이다. Users·Profile 등은 이관되면서 노드가 추가된다.

방법론·라벨링 규칙은 그래프 밖 문서로 분리되어 있다: [lat-methodology](../docs/lat-methodology.md) · [lat-labeling](../docs/lat-labeling.md).
