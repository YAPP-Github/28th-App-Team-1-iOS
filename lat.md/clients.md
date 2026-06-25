# Clients (Repository 계약)

외부 IO 통로. 각 Client 는 **Interface / Live 2개 타겟**으로 분리(`Project.client`).

## 규칙
Client 의존과 구현 분리에 대한 절대 규칙.
- Feature 는 `*ClientInterface` 만 의존. `*ClientLive` 는 **App / Example 만** link → `liveValue` 활성화.
- `testValue` 는 반드시 `unimplemented` (빈 클로저 금지). `previewValue` 는 mock 데이터 허용.

## 목록
현재 정의된 Client 와 메서드, 소비처.

| Client | 메서드 | 쓰는 곳 |
|---|---|---|
| UserClient | `fetchUser(id)` | [[users]] |
| ProfileClient | `fetchProfile(id)`, `saveProfile(p)` | [[profile]] |
| ActivityClient | (활동 조회) | [[activity]] |

## 공유 transport
모든 `*ClientLive` 는 `Networking` 코어 모듈의 `APIClient`(순정 URLSession)를 공유한다. baseURL 은 `@Dependency(\.appConfig)` 가 계별로 주입하고, Networking 은 baseURL·도메인을 모른다 — 순수 transport.

- 외부 라이브러리 의존 0. `URLSession` async API 만 얇게 래핑하며 의존성 seam 은 `APIClient.data` 하나.
- transport 에러(`APIError`)와 도메인 에러(예: `UserClientError`)는 분리 — 도메인 매핑은 각 Live 의 책임.
- `.networking` 은 Live 에만 link (Interface·Feature 는 환경·전송 무관).

## 주의사항
Interface 변경 시 파급 범위.
- Interface 시그니처(메서드/모델) 변경은 Live + 모든 소비 Feature + `testValue` 를 동시에 건드린다. PR 영향 범위에 반드시 표기.
