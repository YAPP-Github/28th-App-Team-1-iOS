# API — D14 서버 연동

YAPP APP 1팀 백엔드(D14 API v1)와의 연동 지식. 서버 태그(Auth·Interview·JD·Job·Portfolio)를 Domain 모듈로 1:1 미러링하고, 공통 규약(envelope·토큰)은 CoreNetwork 가 흡수한다. 인프라 계약은 [[domain.map#네트워킹 인프라]], 레이어 규칙은 [[architecture]].

- Swagger: `http://43.202.34.84:8080/swagger-ui/index.html`
- 스펙 원문: `GET /v3/api-docs` (OpenAPI 3.1)

## 서버와 환경

개발 서버는 `http://43.202.34.84:8080` (HTTP + IP 직결). baseURL 은 계별 xcconfig `API_BASE_URL` → Info.plist → `NetworkClient.defaultBaseURL()` 로 흐른다 (→ DocC Environments). QA/Prod 값은 아직 자리표시자다.

- HTTP 라서 ATS 전면 허용(`NSAllowsArbitraryLoads`)이 걸려 있다 — `Target+Templates.swift` 의 `.app()`/`feature(example:)`. 운영 HTTPS 전환 시 반드시 제거 (App Store 심사에서 사유 요구).

## 공통 규약

모든 응답은 envelope — 성공 `{ success, data }` / 실패 `{ success: false, code, message }`. `NetworkClient.api(...)`/`AuthorizedNetworkClient.api(...)` 가 벗겨서 실패를 `ServerError(code·message·statusCode)` 로 승격한다. `message` 는 그대로 사용자 노출 가능한 한국어 문구다.

- Swagger 스키마 일부는 envelope 없이 표기돼 있다(annotation 누락) → `ServerEnvelope.unwrap` 이 직접 디코드 폴백을 가진다.
- 날짜는 ISO8601 과 LocalDateTime(타임존 표기 없음)이 혼재 → `JSONDecoder.api` 가 KST 가정으로 파싱. 백엔드와 타임존 계약 확정 필요.
- Domain 은 `ServerError.code` 로 도메인 에러를 매핑한다(Auth 가 첫 사례 — AuthError). 아직 매핑 없는 도메인은 ServerError 를 그대로 던진다 — Feature 분기가 필요해지는 시점에 도메인 에러를 늘린다.
- multipart(파일 업로드)는 `NetworkRequest.multipart(...)` 빌더 — 기존 NetworkRequest 계약(헤더+body) 위의 편의일 뿐이다.

## 토큰 수명주기

JWT — Access 3시간 / Refresh 7일, Rotation(재발급 시 페어가 통째로 교체). 보관은 Keychain(`TokenStore`). Feature 는 토큰의 존재를 모른다.

- 인증 필요 요청은 전부 `AuthorizedNetworkClient` 를 쓴다 — Bearer 첨부 후 `TOKEN_EXPIRED`/`INVALID_TOKEN` 이면 **단일 비행** 재발급 → 원요청 1회 재시도. (Rotation 이라 중복 재발급 = 로그아웃 사고 → actor 직렬화)
- `LOGIN_EXPIRED` = Refresh 도 만료 → 토큰 폐기 후 전파. 앱 레벨 재로그인 라우팅 신호.
- 로컬 토큰이 아예 없으면 요청 전에 `NotAuthenticatedError` — 로그인 화면 유도.
- 저장(로그인)·삭제(로그아웃)는 [[api#Auth]] 의 AuthClient 책임.

## Auth

`DomainAuth` — `AuthClient` 파사드에 서버 세션 수명주기가 얹혔다: `login`(자격증명 교환)·`refresh`·`logout`·`check`·`isAuthenticated`. 소셜 SDK 획득부(signIn)와 서버 교환부(login)는 분리된 엔드포인트 — 흐름은 [[auth]].

| 메서드 | 엔드포인트 | 비고 |
|---|---|---|
| `login` | POST `/api/v1/auth/social/login` | KAKAO=액세스 토큰 / APPLE=authorization code 를 credential 로 전송, 성공 시 토큰 저장 |
| `refresh` | POST `/api/v1/auth/token/refresh` | 명시적 재발급 (자동은 AuthorizedNetworkClient) |
| `logout` | DELETE `/api/v1/auth/logout` | 204. 로컬 토큰은 서버 응답과 무관하게 삭제 |
| `check` | GET `/api/v1/auth/check` | 인증 동작 확인(테스트용) |

실패는 `AuthError` 로 매핑된다 — INVALID_CREDENTIAL/SOCIAL_LOGIN_FAILED → invalidCredential, LOGIN_EXPIRED·TOKEN_EXPIRED·INVALID_TOKEN → sessionExpired, transport → networkFailure, 5xx → serverUnavailable.

## Interview

`DomainInterview` — `InterviewClient`. 세션 준비(질문 Preload·요약 질문 TTS)는 서버 비동기 — 생성(202) 후 `sessionStatus` 를 3~5초 폴링하고, READY 에 `startedAt`·요약 질문(base64 TTS)이 동봉된다. FAILED 면 이용권 자동 환불. 계약 상세는 [[interview]].

| 메서드 | 엔드포인트 | 비고 |
|---|---|---|
| `createSession` | POST `/api/v1/interview/sessions` | 이용권 무료 3회, `jdUrl`/`jdText` 상호 배타 |
| `sessionStatus` | GET `/api/v1/interview/sessions/{id}/status` | 3~5초 폴링 |
| `submitAnswer` | POST `/api/v1/interview/sessions/{id}/answers` | 현재 turnLevel=0 전용, 메타=query + 오디오=multipart(mp3) |
| `questionAudioStream` | GET `.../questions/{qid}/audio/stream` | 아래 스트리밍 규약 |

질문 음성 스트리밍 규약: `audio/mpeg` + `Transfer-Encoding: chunked` (Content-Length 없음). 전부 받고 재생하지 말고 `AVURLAsset(url:options:[헤더])` → `AVPlayer` 점진 재생 — 그래서 계약이 Data 가 아니라 `InterviewAudioStream(url·headers)` 다. 중간 실패는 HTTP 로 안 잡힌다 — 재생 에러 콜백으로 감지하고 같은 questionId 로 재호출(TTS 처음부터 재생성).

`endType` 계약(답변 제출): nil=정상 / SKIP(오디오 없음) / MANUAL_END(8:00 후 수동 종료) / HARD_CAP(12:00 강제) / EARLY_EXIT(8:00 전 이탈). `isWrapUp` 은 8:45 경과 여부 — 타이머 상태머신은 [ai-interview](../docs/work/ai-interview.md) §6.

## JD

`DomainJD` — `JDClient.validate`. JD URL 크롤링 + AI 정제 + 서버 캐싱. HTTP 200 이어도 `valid=false` 가 온다(CRAWLING_FAILED·CONTENT_TOO_SHORT·EXTRACTION_FAILED) — 이때 UX 는 본문 직접 입력(jdText) 폴백이 필수.

- POST `/api/v1/jd/validate`
- `createSession` 의 `.url` 입력은 **사전에 이 검증을 통과**해야 한다 (`JD_NOT_VALIDATED`).

## Job

`DomainJob` — `JobClient.jobs`. Setup 위저드 직군 선택지. `jobRole`(서버 Enum 값, 예: BACKEND)을 그대로 `InterviewConfig.jobRole` 로 전달한다 — 클라이언트에 직군 Enum 을 중복 정의하지 않는다. 네트워킹 화면 표준형(NetworkExampleFeature)의 시연 대상이기도 하다.

- GET `/api/v1/jobs`

## Portfolio

`DomainPortfolio` — `PortfolioClient`. PDF 업로드(20MB·30p 이하, 계정당 1개). 등록(202 PROCESSING) 후 `status` 를 3~5초 폴링 — READY 가 돼야 세션 생성에 쓸 수 있다(`PORTFOLIO_PROCESSING` 방지). 재등록은 `PORTFOLIO_ALREADY_EXISTS` → 삭제 후 등록 UX.

| 메서드 | 엔드포인트 | 비고 |
|---|---|---|
| `list` | GET `/api/v1/portfolios` | MVP 1건, 응답은 배열 |
| `register` | POST `/api/v1/portfolios` | 메타=query + PDF=multipart `file` |
| `status` | GET `/api/v1/portfolios/{id}/status` | 3~5초 폴링 |
| `delete` | DELETE `/api/v1/portfolios/{id}` | 재등록 전 필수 (1개 제한) |
