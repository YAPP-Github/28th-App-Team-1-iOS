# Domain Map

도메인(=모듈) 간 큰 그림. 코드 한 줄 단위 연결은 `@lat` 주석, 전체 협업 그림은 이 문서. `refactor/#6` 은 스켈레톤이라 실 Feature 는 Home 뿐이고, 아래 Users↔Profile 등은 이관될 표준 패턴이다.

## 탭 구조
AppFeature 가 각 탭 Feature 를 보유하며 탭끼리는 서로를 모른다. 예정 탭 여럿 중 현재 실체는 Home. → [[home]] · [[app]]

## Users ↔ Profile
가장 중요한 cross-feature 흐름이자 import 그래프엔 안 보이는 의존. **둘은 서로 import 하지 않는다** — 전부 delegate + AppFeature 중재. (이관 후 표준 예시)

```
UserDetail  --delegate(.editProfileTapped)-->  Users
Users       --delegate(.editProfile)-->        AppFeature
AppFeature  --presents editProfile sheet-->    Profile
Profile     --delegate(.profileSaved)-->       AppFeature
AppFeature  --.users(.profileUpdated)-->       Users   (list/detail 갱신)
```

- 조립 지점 → [[app#Cross-feature Routing]]
- **검색**: import 추적으론 안 잡히는 이 의존을 `make lat q=profile` 로 한 번에 찾는다.

## Feature ↔ Domain
각 Feature 가 의존하는 Domain(Interface) 매핑. Repository(Client)는 Domain 레이어 모듈이 보유한다.

| Feature | 의존 Domain (Interface) | Client |
|---|---|---|
| Home | (없음 — 외부 IO 없는 화면) | — |
| Users (예정) | DomainUser | UserClient |
| Profile (예정) | DomainProfile | ProfileClient |

Domain `Implementation`(`liveValue`)은 App / Example 만 link. → [[home]]

## 계획 — AI 면접
YAPP APP 1팀 「AI 면접 연습 앱」을 우리 아키텍처에 녹인 후속 도메인 설계(현재 데모 탭과 별개) — Setup/Session/Report Feature + Domain 군.

- 전체 개요·Part 1/2 → [ai-interview](../docs/work/ai-interview.md)
- **Part 3 분석 보고서 & 영상 복기** → [ai-interview-report](../docs/work/ai-interview-report.md). `FeatureInterviewReport`(R0·R1 + V0·V1·V2, 자체 Path). 신규 Domain: DomainPlayback(영상 자산·재생 시간축) · DomainReview(자기평가 영구 저장), DomainScoring 확장(폴링·기준선).
- ⚠️ cross-feature: `Session --finished--> AppFeature --present--> Report`, `Report --requestFriendFeedback--> AppFeature`. 평가 독립성 — 친구에 넘기는 payload 는 챕터 경계만.
