# Architecture — 지식 그래프 인덱스

이 프로젝트(SwiftUI + TCA · Tuist TMA)의 도메인 지식·설계 의도·cross-feature 숨은 의존을 정의하는 lat.md 노드 목록.

- [[architecture]] — 시스템 총론·레이어·핵심 결정(D1~D3)
- [[domain.map]] — 도메인 간 관계도·cross-feature 숨은 의존
- [[api]] — D14 서버 API ↔ Domain Client 매핑·공통 규약(envelope·토큰·폴링·스트리밍)
- [[app]] — AppFeature 코디네이터·cross-feature 라우팅
- [[deeplink]] — Deeplink 도메인 (유니버설 링크 수신 — 설치/deferred 두 경로·SDK 경계)
- [[home]] — Home 도메인
- [[auth]] — Auth 도메인 (카카오·애플 소셜 로그인 + 서버 세션 교환)
- [[interview]] — Interview 도메인 (InterviewClient — 면접 세션 API)
- [[feedback]] — Feedback 도메인 (G4 게스트 평가 — 무인증 토큰 진입·태도 척도 제출)
- [[onboarding]] — 온보딩 도메인 (면접 재료 수집 위저드 — JD·포폴·대표 프로젝트 + 프리로드)
- [[mypage]] — 마이페이지 도메인 (프로필·포트폴리오 한 달 한 번 규칙·면접 레포트 목록)
- [[report]] — 리포트 도메인 (AI 면접 리포트 — 화면 4종 골격, 디자인 연결 전)

> 실 Feature 노드는 [[home]]·[[auth]]·[[onboarding]]·[[mypage]]·[[report]]. 새 Feature 가 추가되면 노드도 함께 추가한다.

방법론·라벨링 규칙은 그래프 밖 문서로 분리되어 있다: [lat-methodology](../docs/lat-methodology.md) · [lat-labeling](../docs/lat-labeling.md).
