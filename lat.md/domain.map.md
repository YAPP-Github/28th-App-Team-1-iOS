# Domain Map

도메인(=모듈) 간 큰 그림. 코드 한 줄 단위 연결은 `@lat` 주석, 전체 협업 그림은 이 문서.

## 탭 구조 (AppFeature)
4개 탭을 AppFeature 가 보유: **Home · Users · Activity · Profile**. 각 탭은 서로를 모른다.

## Users ↔ Profile (⚠️ import 에 안 보이는 의존)
가장 중요한 cross-feature 흐름. **둘은 서로 import 하지 않는다** — 전부 delegate + AppFeature 중재.

```
UserDetail  --delegate(.editProfileTapped)-->  Users
Users       --delegate(.editProfile)-->        AppFeature
AppFeature  --presents editProfile sheet-->    Profile
Profile     --delegate(.profileSaved)-->       AppFeature
AppFeature  --.users(.profileUpdated)-->       Users   (list/detail 갱신)
```

- `@lat`: [[users#Profile Edit Handoff]] · [[profile#Save]] · [[app#Cross-feature Routing]]
- **검색**: `make lat q=profile` 하면 위 4개 파일이 한 번에 잡힌다. import 추적으론 안 잡힘.

## Feature ↔ Client
| Feature | 의존 Client (Interface) |
|---|---|
| Users | UserClient |
| Profile | ProfileClient |
| Activity | ActivityClient |
| Home | (없음 — 외부 IO 없는 화면) |

`*ClientLive` 는 App / Example 만 link. → [[clients]]

## 계획 — AI 면접 (작업 문서)
YAPP APP 1팀 「AI 면접 연습 앱」을 우리 아키텍처에 녹인 설계 → [[ai-interview]] (Part 1/2 + 전체 개요). (현재 데모 4탭과 별개의 후속 도메인 — Setup/Session/Report Feature + Client군)

- **Part 3 분석 보고서 & 영상 복기** → [[ai-interview-report]]. `InterviewReportFeature`(R0·R1 + V0·V1·V2, 자체 Path). 신규 Client: PlaybackClient(영상 자산·재생 시간축) · ReviewClient(자기평가 영구 저장 → 4.6 '나'), ScoringClient 확장(폴링·기준선).
- ⚠️ cross-feature: `Session --finished--> AppFeature --present--> Report`, `Report --requestFriendFeedback--> AppFeature`. 평가 독립성 — 친구(4.5)에 넘기는 payload 는 챕터 경계만(내 표시·AI 지적 제외).
