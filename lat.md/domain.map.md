# Domain Map

도메인(=모듈) 간 큰 그림. 코드 한 줄 단위 연결은 `@lat` 주석, 전체 협업 그림은 이 문서. `refactor/#6` 은 스켈레톤이라 실 화면은 Home 탭과 FeatureCommon 의 NetworkExample(네트워킹 템플릿)뿐이고, 아래 Users↔Profile 등은 이관될 표준 패턴이다.

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
각 Feature 가 의존하는 Domain(Interface) 매핑. Repository(Client)는 Domain 레이어 모듈이 보유한다. 서버 API Domain 9종(Auth·Interview·InterviewReport·JD·Job·Portfolio·User·FeedbackShare·GuestFeedback)의 엔드포인트·규약은 [[api]].

| Feature | 의존 Domain (Interface) | Client |
|---|---|---|
| Home | (없음 — 외부 IO 없는 화면) | — |
| GuestFeedback (G4 게스트 평가) | DomainGuestFeedback | GuestFeedbackClient · GuestFeedbackLocalStore → [[feedback]] |
| Auth (로그인 게이트) | DomainAuth | AuthClient → [[auth]] |
| Common — NetworkExample (네트워킹 화면 템플릿) | DomainJob | JobClient → [[api#Job]] |
| Onboarding (Part 1 위저드 — [[onboarding]] · [ai-interview](../docs/work/ai-interview.md) §5) | DomainJob · DomainJD · DomainPortfolio (분석 스텝 세션 연결 시 + DomainInterview) | JobClient · JDClient · PortfolioClient (+ InterviewClient) |
| InterviewSession (예정) | DomainInterview | InterviewClient → [[interview]] |
| Portfolio 관리 (예정) | DomainPortfolio | PortfolioClient → [[api#Portfolio]] |
| Users (예정 — 데모 패턴) | DomainUser | UserClient → [[api#User]] |
| InterviewReport (예정 — [ai-interview-report](../docs/work/ai-interview-report.md)) | DomainInterviewReport · DomainFeedbackShare | InterviewReportClient · FeedbackShareClient → [[api#Interview Report]] |
| GuestFeedback (예정 — 지인 웹/딥링크 진입) | DomainGuestFeedback | GuestFeedbackClient → [[api#Guest Feedback]] |
| Profile (예정 — 데모 패턴) | DomainProfile | ProfileClient |

Domain `Implementation`(`liveValue`)은 App / Example 만 link. → [[home]]

## 네트워킹 인프라
모든 외부 HTTP IO 는 `CoreNetwork` 의 `NetworkClient` 계약을 거친다. 소비자는 Domain Implementation 뿐 — Feature 는 Domain(Client)만 알고 이 모듈을 모른다. baseURL 은 계별 xcconfig `API_BASE_URL`(→ DocC Environments)을 liveValue 가 읽는다. 첫 소비자 → [[interview#Client 계약]]

실패는 전부 `NetworkError` 로 정규화된다 — `transport(URLError.Code)`(오프라인·타임아웃), `statusCode(코드, body)`(body = 서버 에러 payload, Domain 이 도메인 에러로 매핑), `invalidResponse`, `invalidURL`/`invalidBaseURL`. 취소는 실패가 아니므로 `CancellationError` 로 나간다. 요청 편의는 `NetworkRequest.json(...)`(Content-Type + Encodable body)·`NetworkRequest.multipart(...)`(파일 업로드), Testing 타겟은 `mock(returning:/json:/throwing:)` 을 제공. Feature→Domain→Core 로 이어지는 화면 표준형은 FeatureCommon `NetworkExampleFeature` (Example 앱은 transport 만 스텁해 Domain liveValue 를 실 구동).

D14 공통 규약(성공/실패 envelope·토큰 수명주기)은 그 위에 얹힌다 — envelope 언랩·`ServerError` 승격은 `api(...)` 확장, Bearer 첨부·단일 비행 재발급은 `AuthorizedNetworkClient`, 토큰 보관은 `TokenStore`(Keychain). 인증 필요 엔드포인트의 Domain liveValue 는 `@Dependency(\.authorizedNetworkClient)` 를 쓴다. 상세 → [[api#공통 규약]] · [[api#토큰 수명주기]]

## 계획 — AI 면접
YAPP APP 1팀 「AI 면접 연습 앱」을 우리 아키텍처에 녹인 후속 도메인 설계(현재 데모 탭과 별개) — Onboarding(Part1)/Session/Report Feature + Domain 군. Part 1 은 PRD v3 로 `FeatureOnboarding` 구현 중(초안 가칭 InterviewSetup 실현). 서버 연동 Domain 은 [[api]] 미러링으로 실체화됐다.

- 전체 개요·Part 1/2 → [ai-interview](../docs/work/ai-interview.md)
- 기획 시점 Client 설계와 실 서버의 대응: QuestionClient → **InterviewClient**(질문 생성·턴 진행이 세션 API 로 통합, [[api#Interview]]) · PortfolioClient → 동명([[api#Portfolio]]) · 직군/JD 입력 → **JobClient·JDClient**. SpeechClient(TTS/STT)·PermissionClient·RecordingClient 는 디바이스 측 IO 라 별개로 남는다(서버 API 아님).
- **Part 3 분석 보고서 & 영상 복기** → [ai-interview-report](../docs/work/ai-interview-report.md). `FeatureInterviewReport`(R0·R1 + V0·V1·V2, 자체 Path). 신규 Domain: DomainPlayback(영상 자산·재생 시간축) · DomainReview(자기평가 영구 저장), DomainScoring 확장(폴링·기준선).
- ⚠️ cross-feature: `Session --finished--> AppFeature --present--> Report`, `Report --requestFriendFeedback--> AppFeature`. 평가 독립성 — 친구에 넘기는 payload 는 챕터 경계만.
