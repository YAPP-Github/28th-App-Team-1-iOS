# Clients (Repository 계약)

외부 IO 통로. 각 Client 는 **Interface / Live 2개 타겟**으로 분리(`Project.client`).

## 규칙
- Feature 는 `*ClientInterface` 만 의존. `*ClientLive` 는 **App / Example 만** link → `liveValue` 활성화.
- `testValue` 는 반드시 `unimplemented` (빈 클로저 금지). `previewValue` 는 mock 데이터 허용.

## 목록
| Client | 메서드 | 쓰는 곳 |
|---|---|---|
| UserClient | `fetchUser(id)` | [[users]] |
| ProfileClient | `fetchProfile(id)`, `saveProfile(p)` | [[profile]] |
| ActivityClient | (활동 조회) | [[activity]] |

## 주의사항
- Interface 시그니처(메서드/모델) 변경은 Live + 모든 소비 Feature + `testValue` 를 동시에 건드린다. PR 영향 범위에 반드시 표기.
