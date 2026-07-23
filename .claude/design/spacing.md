# Spacing · Outline 토큰

`SharedDesignSystem/Interface/Spacing/DSSpacing.swift` — 순수 Swift. Figma 스케일이 불규칙이라 t-shirt 매핑 대신 **수치 보존**(타이포가 Figma명 보존한 철학과 동일).

## Spacing (`DSSpacing`)

접근: `.padding(.ds(.p20))`.

| 토큰 | pt | 토큰 | pt |
|---|---|---|---|
| `p4` | 4 | `p14` | 14 |
| `p8` | 8 | `p20` | 20 |
| `p10` | 10 | `p22` | 22 |
| `p12` | 12 | `p24` | 24 |

## Outline (`DSOutline`)

테두리 두께. Figma outline-s/m 은 Swift 식별자 최소 길이 규칙(SwiftLint)에 맞춰 `small`/`medium` 으로 풀어썼다 — 값은 Figma 그대로. 접근: `.strokeBorder(…, lineWidth: .ds(.medium))`.

| 토큰 | pt | Figma |
|---|---|---|
| `small` | 1 | outline-s |
| `medium` | 1.2 | outline-m |
| `large` | 4 | — |
| `mega` | 6 | — |

## 규칙

- 하드코딩 수치(`.padding(16)`) 대신 토큰. 스케일에 없는 값이 필요하면 디자인 재확인 후 케이스 추가.
- 값 단일 소스 = 코드(`DSSpacing`/`DSOutline`) — Figma 수치와 대조해 이 문서를 갱신한다. 어긋나면 코드 우선.
