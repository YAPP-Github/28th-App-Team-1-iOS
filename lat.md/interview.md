# Interview 도메인

AI 면접 연습의 중심 도메인. `DomainInterview` 가 D14 면접 세션 API([[api#Interview]])의 모델과 Repository 계약(`InterviewClient`)을 보유한다. 소비 Feature(Setup/Session 군)는 [ai-interview](../docs/work/ai-interview.md) 설계대로 추가되면서 `.domain(interface: .interview)` 로 연결된다.

## Client 계약
`InterviewClient` 는 Feature 가 Interview 데이터에 접근하는 유일한 통로 — `createSession`(생성)·`sessionStatus`(준비 폴링)·`submitAnswer`(답변 제출)·`questionAudioStream`(질문 TTS 재생 정보).

Interface 에 계약 + `testValue`(unimplemented) + `previewValue`(샘플), Implementation 에 `liveValue` — 구현은 App/Example 만 link 한다(D4).

- 입력 모델 `InterviewConfig` 는 Setup 위저드 산출물 — jdUrl/jdText 상호 배타는 `JobDescriptionInput` enum 으로 타입에 새겼다.
- `questionAudioStream` 은 Data 가 아니라 `InterviewAudioStream(url·headers)` 를 준다 — chunked TTS 를 AVPlayer 로 점진 재생해야 해서다([[api#Interview]] 스트리밍 규약).
- 에러는 `InterviewError`(도메인) 로 노출한다 — liveValue 가 Core `ServerError` 코드를 `.freeTextNotRelevant`(연관성 부족)·`.noRemainingTicket`·`.server(code,message)` 로 매핑해, Feature 가 Core 를 모르고도(레이어) 코드별 분기한다. 온보딩 분석 스텝이 `.freeTextNotRelevant` 를 잡아 집중 프로젝트로 되돌린다 → [[onboarding#분석]].

## API
서버 계약이 바뀌면 이 섹션·[[api#Interview]]·`liveValue` 를 함께 갱신한다. 인프라는 [[domain.map#네트워킹 인프라]] 의 `AuthorizedNetworkClient` 계약만 사용 — Bearer 첨부·토큰 재발급은 인프라 몫이고 liveValue 는 경로 조립·인코딩·디코딩만 한다.

- 세션 준비는 서버 비동기: POST(202) → 3~5초 status 폴링 → READY 에 `startedAt` + 요약 질문(base64 TTS). FAILED 는 이용권 자동 환불.
- `submitAnswer` 는 현재 turnLevel=0(첫 턴) 전용 — 서버가 일반 턴을 여는 시점에 확장한다. 메타데이터는 query, 오디오(mp3)만 multipart.
- liveValue 는 URLSession·토큰을 모르므로 테스트도 Core 구현 없이 AuthorizedNetworkClient 스텁으로 검증한다 (`InterviewClientLiveTests`).
