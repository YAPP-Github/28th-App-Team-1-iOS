# @lat 라벨링 규칙 — 코드 주석 컨벤션

> lat 방법론의 **장치 2**(코드 ↔ 도메인 색인)의 실행 스펙.
> 개념·전체 그림은 [lat-methodology](lat-methodology.md). 이 문서는 **코드에 무엇을, 어떻게 적는가**만 정한다.
> Claude 는 Feature·AppFeature·Client 코드를 작성·수정할 때 이 규칙대로 주석을 추가·갱신한다.

## 왜 다나

핵심 규칙 D1 — **Feature → Feature 의존 0 (delegate-only)** — 때문에 cross-feature 의존이 `import` 그래프에 **안 보인다.** `@lat` 라벨이 그 보이지 않는 연결을 코드에 적어두어, `lat refs`/`lat search` 한 줄로 *"이거 고치면 어디가 영향받나"* 를 즉시 찾게 한다.

## 라벨 종류

| 라벨 | 의미 | 형식 |
|---|---|---|
| `@lat:` | 이 코드가 **소속된** 도메인·섹션 | `// @lat: [[domain#Section]]` |
| `depends-on:` | 이 코드가 **의존하는** 곳 (없으면 안 돎 / 바꾸면 영향받음) | `// depends-on: [[domain#Section]], [[other]]` |
| `@lat:` (테스트) | 테스트가 검증하는 스펙 | `// @lat: [[tests#Case]]` (테스트 코드에) |

- `[[domain]]` = `lat.md/` 의 파일명(확장자 없이). `[[users]]` → `lat.md/users.md`.
- `[[domain#Section]]` 의 `#Section` 은 **헤딩 텍스트 전체**와 일치해야 한다 → 헤딩에 ⚠️·괄호 데코레이션 금지(안 그러면 `[[profile#Save]]` 가 안 맞음). 모든 섹션은 **≤250자 선행 문단**으로 시작해야 `lat check` 통과. (헤딩이 바뀌면 라벨도 갱신)
- `depends-on:` 뒤에는 괄호로 짧은 부연을 붙일 수 있다 → `depends-on: [[clients]] (ProfileClient#fetchProfile)`. **단 `depends-on:` 은 lat.md 가 검증하지 않는 로컬 관례**(`lat check` 는 `@lat:` 만 본다) — 사람이 읽는 cross-feature 의존 메모.
- 테스트↔스펙은 별도 `@lat-test:` 가 아니라, **스펙 섹션에 `lat: { require-code-mention: true }` frontmatter** 를 달고 테스트 코드에서 `// @lat:` 로 그 섹션을 가리키면 `lat check` 가 커버리지를 강제한다.

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

## 검색·검증 (lat CLI)

```bash
lat refs "profile#Save"   # 이 섹션을 가리키는 코드·문서 역참조
lat search "프로필 저장"    # 의미 검색 (LLM 키 필요)
lat check                 # 끊긴 링크·코드 ref 검증 (작업 후 필수)
```

(도구 없이 빠른 grep 만 필요하면 `make lat q=profile` 폴백.)

## 유지 규칙

- 새 cross-feature delegate 를 추가하면 → 그 자리에 `depends-on:` 을 추가한다.
- 코드를 다른 도메인으로 옮기면 → `@lat:` 을 갱신한다.
- lat.md 문서의 헤딩을 바꾸면 → 그 `#Section` 을 가리키는 라벨을 갱신한다 (`lat check` 로 확인).
- 라벨이 가리키는 `[[domain]]` 문서·`#Section` 헤딩은 존재해야 한다 — **dangling 금지.** (예: `[[app#Cross-feature Routing]]` → `app.md` 의 `## Cross-feature Routing` 헤딩)
