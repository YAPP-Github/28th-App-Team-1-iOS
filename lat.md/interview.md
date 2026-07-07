# Interview 도메인

AI 면접 연습의 중심 도메인. 첫 실 Domain 모듈(`DomainInterview`)로 면접 세션 모델(`Interview`)과 Repository 계약(`InterviewClient`)을 보유한다. 소비 Feature(Setup/Session 군)는 [ai-interview](../docs/work/ai-interview.md) 설계대로 추가되면서 `.domain(interface: .interview)` 로 연결된다.

## Client 계약
`InterviewClient` 는 Feature 가 Interview 데이터에 접근하는 유일한 통로. Interface 에 계약 + `testValue`(unimplemented) + `previewValue`(샘플), Implementation 에 `liveValue` — 구현은 App/Example 만 link 한다(D4). 인프라는 [[domain.map#네트워킹 인프라]] 의 NetworkClient 계약만 사용.

## API
서버 계약(백엔드 진행 중)이 바뀌면 이 섹션과 `liveValue` 를 함께 갱신한다. 현재 `GET /interviews` → `[Interview]` (id·title·createdAt, ISO-8601). liveValue 는 URLSession 을 모르므로 테스트도 Core 구현 없이 NetworkClient 스텁으로 검증한다.
