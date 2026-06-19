# @lat 라벨링 규칙 — 코드 주석 컨벤션

> lat 방법론의 **장치 2**(코드 ↔ 도메인 색인)의 실행 스펙.
> 개념·전체 그림은 [README](README.md). 이 문서는 **코드에 무엇을, 어떻게 적는가**만 정한다.
> Claude 는 Feature·AppFeature·Client 코드를 작성·수정할 때 이 규칙대로 주석을 추가·갱신한다.

## 왜 다나

핵심 규칙 D1 — **Feature → Feature 의존 0 (delegate-only)** — 때문에 cross-feature 의존이 `import` 그래프에 **안 보인다.** `@lat` 라벨이 그 보이지 않는 연결을 코드에 적어두어, `make lat`/`make lat-deps` 한 줄로 *"이거 고치면 어디가 영향받나"* 를 즉시 찾게 한다.

## 라벨 종류

| 라벨 | 의미 | 형식 |
|---|---|---|
| `@lat:` | 이 코드가 **소속된** 도메인·섹션 | `// @lat: [[domain#Section]]` |
| `depends-on:` | 이 코드가 **의존하는** 곳 (없으면 안 돎 / 바꾸면 영향받음) | `// depends-on: [[domain#Section]], [[other]]` |
| `@lat-test:` | *(제안, 미도입)* 이 코드의 검증 테스트 | `// @lat-test: [[tests#Case]]` |

- `[[domain]]` = `lat.md/` 의 파일명(확장자 없이). `[[users]]` → `lat.md/users.md`.
- `[[domain#Section]]` 의 `#Section` 은 그 문서의 **실제 헤딩**과 일치해야 한다. (헤딩이 바뀌면 라벨도 갱신)
- `depends-on:` 뒤에는 괄호로 짧은 부연을 붙일 수 있다 → `depends-on: [[clients]] (ProfileClient#fetchProfile)`.

## 어디에 다나

각 `XxxFeature.swift` 의 **Reducer 선언부 바로 위**에 1~2줄. View 파일에는 달지 않는다 — 의도·의존은 Reducer 가 가진다.

```swift
// @lat: [[users#Profile Edit Handoff]]
// depends-on: [[profile#Save]], [[app#Cross-feature Routing]]
@Reducer
public struct UsersFeature { ... }
```

대상:

- **모든 Feature Reducer** — `@lat:` 필수. cross-feature/Client 의존이 있으면 `depends-on:` 추가.
- **AppFeature(코디네이터)** — `@lat: [[app#Cross-feature Routing]]` + 보유한 Feature 들을 `depends-on:`.
- **cross-feature delegate 출구/입구** — 가장 중요. `import` 에 안 보이는 연결이므로 반드시 `depends-on:` 으로 명시한다.

## 실제 예 (현재 코드)

```swift
// AppFeature.swift
// @lat: [[app#Cross-feature Routing]]
// depends-on: [[home]], [[users]], [[activity]], [[profile]]

// UsersFeature.swift
// @lat: [[users#Profile Edit Handoff]]
// depends-on: [[profile#Save]], [[app#Cross-feature Routing]]

// ProfileFeature.swift
// @lat: [[profile#Save]]
// depends-on: [[clients]] (ProfileClient#fetchProfile, #saveProfile)
```

## 검색 (Makefile)

```bash
make lat q=profile        # [[profile 가 달린 코드 전부 (delegate 의존 포함)
make lat-deps q=profile   # profile 을 depends-on 하는 코드 = 바꾸면 영향받는 곳
make lat-all              # 코드 전체 @lat 라벨 목록
```

## 유지 규칙

- 새 cross-feature delegate 를 추가하면 → 그 자리에 `depends-on:` 을 추가한다.
- 코드를 다른 도메인으로 옮기면 → `@lat:` 을 갱신한다.
- lat.md 문서의 헤딩을 바꾸면 → 그 `#Section` 을 가리키는 라벨을 갱신한다 (`make lat q=<domain>` 으로 확인).
- 라벨이 가리키는 `[[domain]]` 문서는 존재해야 한다 — **dangling 금지.**

> 참고: 현재 `[[app]]` 은 전용 문서(`app.md`)가 아직 없다. AppFeature 코디네이터 도메인 doc 신설은 백로그 — 그 전까지 `[[app#…]]` 은 의도상 앵커로만 쓴다.
