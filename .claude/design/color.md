# 색상 — 상세

`Color` 팔레트 토큰 레퍼런스. 단일 소스는 [Color+Palette.swift](../../Projects/Shared/SharedDesignSystem/Interface/Color/Color+Palette.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. 원본 스펙: Figma «Hilit_Color_Guide» (node 366-173).

## 사용법

```swift
Text("제목").foregroundStyle(Color.HilitGreen.g500)   // 패밀리 enum . 토큰
Rectangle().fill(Color.Gray.g50)
```

## 팔레트 (23색)

에셋명은 HEX(`Color636777`), 접근은 패밀리 enum. 토큰명은 색 약어 + Figma 스케일 번호(`g600` = gray 600).

| enum | 토큰 | HEX | 용도 |
|---|---|---|---|
| `HilitBlack` | `b800` | #1A1B1F | 메인 블랙·텍스트 |
| | `b900` | #121316 | 다크모드 배경 |
| `HilitGreen` | `g500` | #ACEBA0 | 메인 그린 |
| | `g600` | #88C97C | — |
| | `g800` | #106100 | 그린 텍스트 |
| `Negative` | `n200` | #FFEBEB | 레드 배경 |
| | `n300` | #FFA6A6 | — |
| | `n400` | #FF8383 | — |
| | `n500` | #FF5757 | 메인 레드·레드 텍스트 |
| `Positive` | `p200` | #DDFAFF | 블루 배경 |
| | `p500` | #00CFEF | 메인 블루 |
| | `p800` | #008A9F | 블루 텍스트 |
| `Gray` | `g50` | #F6F7F9 | 그레이 배경 |
| | `g100` | #EBECF1 | — |
| | `g200` | #BCBEC6 | — |
| | `g300` | #9DA0AC | disabled 상태 텍스트 |
| | `g400` | #8A8D9C | — |
| | `g500` | #6D7183 | 그레이 텍스트 |
| | `g600` | #636777 | — |
| | `g700` | #494C58 | — |
| | `g800` | #31333B | — |
| | `g900` | #27282F | — |
| `BlackWhite` | `white` | #FFFFFF | — |

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Colors.xcassets`(에셋명 = `Color<HEX>`), 로드는 `Color.load(_:)` 단일 seam ([Color+Load.swift](../../Projects/Shared/SharedDesignSystem/Interface/Color/Color+Load.swift)). 개발 빌드에서 이름 오타를 `assert` 로 조기 검출 — 폰트의 `Pretendard.registerOnce` 와 같은 역할.
- **스펙 검증**: `ColorPaletteTests` 가 토큰 → 에셋 RGB 를 Figma 확정 HEX 와 1:1 대조. static-library 모드의 번들(`Bundle.module`) 파손도 여기서 잡힌다.
- **알려진 Figma 불일치**: Color Guide 스크린샷의 positive 계열 HEX **텍스트 라벨**(#FEF4E7·#F29411·#FEEFF4, 주황)은 낡았다 — 실제 스와치·바인딩 변수·"블루" 설명과 어긋난다. 바인딩 변수값(#DDFAFF·#00CFEF·#008A9F, 청록)을 확정으로 채택 (2026-07-23). 디자이너에게 라벨 정정 요청 상태.
- **다크모드 미반영**: 각 토큰은 현재 단일 appearance(universal). 도입 결정 시 colorset 에 dark variant 추가.
