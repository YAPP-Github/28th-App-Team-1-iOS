# Spacing · Outline 토큰

`SharedDesignSystem/Interface/Spacing/DSSpacing.swift` — 순수 Swift. Figma 스케일이 불규칙이라 t-shirt 매핑 대신 **수치 보존**(타이포가 Figma명 보존한 철학과 동일).

## Spacing (`DSSpacing`)

접근: `.padding(.ds(.p20))`.

| 토큰 | pt | 토큰 | pt |
|---|---|---|---|
| `p4` | 4 | `p16` | 16 |
| `p8` | 8 | `p20` | 20 |
| `p10` | 10 | `p22` | 22 |
| `p12` | 12 | `p24` | 24 |
| `p14` | 14 | `p40` | 40 |

## Outline (`DSOutline`)

테두리 두께. Figma outline-s/m/sb 는 Swift 식별자 최소 길이 규칙(SwiftLint)에 맞춰 `small`/`medium`/`semiBold` 로 풀어썼다 — 값은 Figma 그대로. 접근: `.strokeBorder(…, lineWidth: .ds(.medium))`.

| 토큰 | pt | Figma |
|---|---|---|
| `small` | 1 | outline-s |
| `medium` | 1.2 | outline-m |
| `semiBold` | 1.5 | outline-sb |
| `large` | 4 | outline-large |
| `mega` | 6 | outline-mega |

`semiBold` 는 «카드 판 테두리·선택 밑줄» 두께다 — `ButtonLarge(.outlined)` 테두리, `TabSelector` 선택 밑줄, `FileCard`·`FoldableCard`·`FileUpload` 파일 행 테두리가 쓴다.

## 규칙

- 하드코딩 수치(`.padding(16)`) 대신 토큰. 스케일에 없는 값이 필요하면 디자인 재확인 후 케이스 추가.
- 값 단일 소스 = 코드(`DSSpacing`/`DSOutline`) — Figma 수치와 대조해 이 문서를 갱신한다. 어긋나면 코드 우선.
