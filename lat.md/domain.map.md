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
각 Feature 가 의존하는 Domain(Interface) 매핑. Repository(Client)는 Domain 레이어 모듈이 보유한다.

| Feature | 의존 Domain (Interface) | Client |
|---|---|---|
| Home | (없음 — 외부 IO 없는 화면) | — |
| Common — NetworkExample (네트워킹 화면 템플릿) | DomainInterview | InterviewClient → [[interview]] |
| Interview 군 (예정 — [ai-interview](../docs/work/ai-interview.md)) | DomainInterview | InterviewClient → [[interview]] |
| Users (예정) | DomainUser | UserClient |
| Profile (예정) | DomainProfile | ProfileClient |

Domain `Implementation`(`liveValue`)은 App / Example 만 link. → [[home]]

## 네트워킹 인프라
모든 외부 HTTP IO 는 `CoreNetwork` 의 `NetworkClient` 계약을 거친다. 소비자는 Domain Implementation 뿐 — Feature 는 Domain(Client)만 알고 이 모듈을 모른다. baseURL 은 계별 xcconfig `API_BASE_URL`(→ DocC Environments)을 liveValue 가 읽는다. 첫 소비자 → [[interview#Client 계약]]

실패는 전부 `NetworkError` 로 정규화된다 — `transport(URLError.Code)`(오프라인·타임아웃), `statusCode(코드, body)`(body = 서버 에러 payload, Domain 이 도메인 에러로 매핑), `invalidResponse`, `invalidURL`/`invalidBaseURL`. 취소는 실패가 아니므로 `CancellationError` 로 나간다. 요청 편의는 `NetworkRequest.json(...)`(Content-Type + Encodable body), Testing 타겟은 `mock(returning:/json:/throwing:)` 을 제공. Feature→Domain→Core 로 이어지는 화면 표준형은 FeatureCommon `NetworkExampleFeature` (Example 앱은 transport 만 스텁해 Domain liveValue 를 실 구동).

## 푸시 인프라
모든 푸시(FCM/APNs) IO 는 `CorePush` 의 `PushClient` 계약을 거친다. Firebase SDK 는 CorePushImplementation(PushCenter)에 격리 — App 은 AppDelegate lifecycle 을 seam 에 연결만 하고 SDK 를 모른다. 스트림의 유일 소비자는 AppFeature. → [[app#푸시 배선]]

- 계약: `configure`(Firebase 초기화 — GoogleService-Info.plist 없으면 경고 후 no-op graceful), `requestAuthorization`(권한 + APNs 등록), `registerAPNSToken`(AppDelegate 콜백 전달), `fcmTokenUpdates`/`events`(AsyncStream).
- 스위즐링 비활성(`FirebaseAppDelegateProxyEnabled=NO`) — APNs 토큰은 AppDelegate 가 명시적으로 전달한다. 스트림 continuation 은 eager 생성이라 cold-start 알림 탭도 구독(onAppear) 전 버퍼에 보존된다.
- 수신 payload 는 `PushNotification`(title/body + String 전용 data)으로 정제되어 경계를 넘는다 — UN/FCM 원본 타입은 Implementation 밖으로 안 나간다.
- FCM 토큰의 백엔드 등록은 미구현(TODO seam: AppFeature `fcmTokenUpdated`) — 서버 스펙 확정 시 Domain 모듈(예: DomainNotification)이 이 인프라와 위 네트워킹 인프라를 조합한다. Testing 타겟은 `mock(authorizationGranted:/tokens:/events:)` 제공.

## 계획 — AI 면접
YAPP APP 1팀 「AI 면접 연습 앱」을 우리 아키텍처에 녹인 후속 도메인 설계(현재 데모 탭과 별개) — Setup/Session/Report Feature + Domain 군.

- 전체 개요·Part 1/2 → [ai-interview](../docs/work/ai-interview.md)
- **Part 3 분석 보고서 & 영상 복기** → [ai-interview-report](../docs/work/ai-interview-report.md). `FeatureInterviewReport`(R0·R1 + V0·V1·V2, 자체 Path). 신규 Domain: DomainPlayback(영상 자산·재생 시간축) · DomainReview(자기평가 영구 저장), DomainScoring 확장(폴링·기준선).
- ⚠️ cross-feature: `Session --finished--> AppFeature --present--> Report`, `Report --requestFriendFeedback--> AppFeature`. 평가 독립성 — 친구에 넘기는 payload 는 챕터 경계만.
