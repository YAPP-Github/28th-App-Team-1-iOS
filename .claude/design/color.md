# 색상 — 상세

`DSColor` 팔레트 + `Color` 시맨틱 토큰 레퍼런스. 단일 소스는 [DSColor.swift](../../Projects/Shared/SharedDesignSystem/Interface/Color/DSColor.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. 원본 스펙: Figma «Hilit_Color_Guide» (node 366-173).

## 사용법

```swift
Text("제목").foregroundStyle(.dsTextPrimary)   // 시맨틱 토큰 — 화면 코드는 이쪽 우선
Color.ds(.gray900)                             // 원시 팔레트 — 시맨틱에 없는 특정 shade 가 필요할 때
```

## 원시 팔레트 (`DSColor`, 23색)

케이스명은 Figma 색상명을 Swift 식별자로 변환 (`hilitBlack800` = "hilit black/800"). `figmaName`·`hex` 프로퍼티로 원본 확인 가능.

| 그룹 | 토큰 | HEX | 용도 |
|---|---|---|---|
| hilit black | `hilitBlack800` | #1A1B1F | 메인 블랙·텍스트 |
| | `hilitBlack900` | #121316 | 다크모드 배경 |
| hilit green | `hilitGreen500` | #ACEBA0 | 메인 그린 |
| | `hilitGreen600` | #88C97C | — |
| | `hilitGreen800` | #106100 | 그린 텍스트 |
| negative (error) | `error200` | #FFEBEB | 레드 배경 |
| | `error300` | #FFA6A6 | — |
| | `error400` | #FF8383 | — |
| | `error500` | #FF5757 | 메인 레드·레드 텍스트 |
| positive | `positive200` | #DDFAFF | 블루 배경 |
| | `positive500` | #00CFEF | 메인 블루 |
| | `positive800` | #008A9F | 블루 텍스트 |
| grayscale | `gray50` | #F6F7F9 | 그레이 배경 |
| | `gray100` | #EBECF1 | — |
| | `gray200` | #BCBEC6 | — |
| | `gray300` | #9DA0AC | disabled 상태 텍스트 |
| | `gray400` | #8A8D9C | — |
| | `gray500` | #6D7183 | 그레이 텍스트 |
| | `gray600` | #636777 | — |
| | `gray700` | #494C58 | — |
| | `gray800` | #31333B | — |
| | `gray900` | #27282F | — |
| black & white | `white` | #FFFFFF | — |

## 시맨틱 토큰 (`Color.ds*`)

Figma 용도 주석을 역할로 매핑한 별칭. **화면 코드는 원시 팔레트보다 이쪽을 우선한다.**

| 토큰 | → 팔레트 | 용도 |
|---|---|---|
| `.dsPrimary` | hilitGreen500 | 메인 브랜드 그린 |
| `.dsBackground` | gray50 | 기본 배경 |
| `.dsTextPrimary` | hilitBlack800 | 기본 텍스트 |
| `.dsTextSecondary` | gray500 | 보조 텍스트 |
| `.dsTextDisabled` | gray300 | 비활성 텍스트 |
| `.dsError` | error500 | 오류 강조·텍스트 |
| `.dsErrorBackground` | error200 | 오류 배경 |
| `.dsPositive` | positive500 | 긍정 강조 |
| `.dsPositiveBackground` | positive200 | 긍정 배경 |

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Colors.xcassets` 콜러셋(에셋명 = 케이스명), 로드는 `Color.load(_:)` 단일 seam ([Color+Load.swift](../../Projects/Shared/SharedDesignSystem/Interface/Color/Color+Load.swift)). 개발 빌드에서 이름 오타를 `assert` 로 조기 검출 — 폰트의 `Pretendard.registerOnce` 와 같은 역할.
- **스펙 검증**: 토큰↔Figma명, 에셋 RGB↔확정 HEX 1:1 은 `DSColorTests` 가 고정. static-library 모드에서 Tuist 합성 번들(`Bundle.module`)이 깨져도 여기서 잡힌다. 팔레트 개정 시 이 표부터 Figma 와 대조해 갱신.
- **알려진 Figma 불일치**: Color Guide 스크린샷의 positive 계열 HEX **텍스트 라벨**(#FEF4E7·#F29411·#FEEFF4, 주황)은 낡았다 — 실제 스와치·바인딩 변수·"블루" 설명과 어긋난다. 바인딩 변수값(#DDFAFF·#00CFEF·#008A9F, 청록)을 확정으로 채택 (2026-07-23). 디자이너에게 라벨 정정 요청 상태.
- **다크모드 미반영**: 각 토큰은 현재 단일 appearance(universal). Figma 가 `hilit black/900` 을 "다크모드 배경" 으로 주석하나 확정 팔레트는 라이트 단일값 — 도입 결정 시 colorset 에 dark variant 추가.
