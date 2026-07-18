# Color — HILIT 색 토큰

단일 소스: `Shared/SharedDesignSystem/Interface/Colors/Color+DS.swift` + `Interface/Resources/Colors.xcassets`. Figma 색 변수와 1:1, 라이트 단일 값(다크모드 제한).

| 토큰 | Figma 변수 | hex | 용도 |
|---|---|---|---|
| `Color.dsBlack` | hilit black | #1A1B1F | CTA·뱃지 바탕, 강조 보더, 진행 바 활성 |
| `Color.dsWhite` | hilit white | #FFFFFF | 화면·칩 바탕 |
| `Color.dsGreen500` | hilit green/500 | #ACEBA0 | 브랜드 그린 포인트 |
| `Color.dsGray50` | grayscale/gray-50 | #F0F1F3 | 옅은 면 (진행 바 비활성 등) |
| `Color.dsGray400` | grayscale/gray-400 | #8A8D9C | 비활성 텍스트 |
| `Color.dsGray500` | Gray scale/500 | #8990A0 | 보조 텍스트 |
| `Color.dsGray800` | Gray scale/800 | #262A30 | 강조 본문 텍스트 |

## 규칙

- 새 색 추가: `Colors.xcassets` 에 colorset 추가 → `Color.load("Name")` 으로 토큰 노출 (design.md 에셋 로드 규칙). 직접 `Color(red:…)` 남발 금지.
- Figma 에서 변수 미바인딩 raw 값(예: 칩 보더 #EDEDED)은 섣불리 토큰화하지 않는다 — 사용처 private 상수 + 주석으로 보류하고, 디자인 시스템에 변수가 생기면 승격.
- 이미지 토큰도 동일 seam: `Image.load(_:)` + `Image.DS` 네임스페이스 (현재 `Image.DS.icClose`).
