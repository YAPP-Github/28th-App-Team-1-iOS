# 색상 — 상세

`Color` 팔레트 토큰 레퍼런스. 단일 소스는 [Color+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Color/Color+Extension.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. 원본 스펙: Figma «Hilit_Color_Guide» (node 366-173).

## 사용법

```swift
Text("제목").foregroundStyle(Color.HilitGreen.g500)   // 패밀리 enum . 토큰
Rectangle().fill(Color.GrayScale.g50)
```

## 팔레트 (23색)

에셋명은 HEX(`Color636777`), 접근은 패밀리 enum. 토큰명은 색 약어 + Figma 스케일 번호(`g600` = gray 600). 카탈로그도 아래 enum 과 같은 6개 그룹 폴더로 묶여 있다 — Figma 의 «negative» 는 `Error`, «Grayscale» 은 `GrayScale` 로 통일했다.

| enum | 토큰 | HEX | 생김새 · 용도 |
|---|---|---|---|
| `HilitBlack` | `b800` | #1A1B1F | 거의 검정 — 메인 블랙. 본문 텍스트·검정 버튼 배경 |
| | `b900` | #121316 | 완전 검정에 가까움 — 다크 화면 배경 |
| `HilitGreen` | `g500` | #ACEBA0 | 연두 형광 — 메인 그린. 마커·선택 강조 배경 |
| | `g600` | #88C97C | 차분한 연두 — 그린 요소의 테두리 |
| | `g800` | #106100 | 짙은 숲색 — 그린 배경 위 텍스트 |
| `Error` | `e200` | #FFEBEB | 아주 연한 분홍 — 레드 배지·버튼 배경 |
| | `e300` | #FFA6A6 | 연한 살구빛 빨강 |
| | `e400` | #FF8383 | 중간 빨강 |
| | `e500` | #FF5757 | 선명한 빨강 — 메인 레드. 에러 텍스트·경고 |
| `Positive` | `p200` | #DDFAFF | 아주 연한 하늘 — 블루 배지·버튼 배경 |
| | `p500` | #00CFEF | 밝은 청록(시안) — 메인 블루 |
| | `p800` | #008A9F | 짙은 청록 — 블루 배경 위 텍스트 |
| `GrayScale` | `g50` | #F6F7F9 | 종이빛 회백 — 회색 배경·disabled 버튼 배경 |
| | `g100` | #EBECF1 | 옅은 회색 — 카드 테두리·칩 배경 |
| | `g200` | #BCBEC6 | 흐린 회색 |
| | `g300` | #9DA0AC | 중간 회색 — disabled 텍스트 |
| | `g400` | #8A8D9C | 회색 — 보조 아이콘·다크 판 disabled 라벨 |
| | `g500` | #6D7183 | 짙은 회색 — 보조 텍스트 |
| | `g600` | #636777 | 더 짙은 회색 |
| | `g700` | #494C58 | 어두운 회색 — 밝은 배경 위 진한 보조 텍스트 |
| | `g800` | #31333B | 거의 검정 회색 |
| | `g900` | #27282F | 검정에 가까운 회색 — pressed 배경 |
| `BlackWhite` | `white` | #FFFFFF | 흰색 |

**생김새로 찾을 때**: 「형광 연두」→ `HilitGreen.g500`, 「연한 하늘 배경」→ `Positive.p200`, 「disabled 회색 글자」→ `GrayScale.g300` 처럼 위 표의 생김새 열을 훑는다. HEX 를 아는 경우 그대로 검색.

## 팔레트 밖 — `Brand`

외부 제공자 브랜드 색. HILIT 스케일에 자리가 없고 상대 가이드라인이 값을 고정하므로 **23색 팔레트와 섞지 않고** 따로 묶는다 — 카탈로그의 6그룹과 `ColorPaletteTests` 의 23색 불변식은 그대로 유지된다.

| enum | 토큰 | HEX | 생김새 · 용도 |
|---|---|---|---|
| `Brand` | `kakao` | #FEE500 | 카카오 노랑 — 카카오 로그인 버튼 배경 (`ButtonLarge(_:login: .kakao)`) |

에셋은 `Colors.xcassets/Brand/ColorFEE500`. 새 제공자 색(네이버 등)이 들어오면 같은 enum 에 추가하고 팔레트 표는 건드리지 않는다.

## 구현 노트

- **에셋 로드**: 값은 `Interface/Resources/Colors.xcassets`(에셋명 = `Color<HEX>`), 로드는 Tuist 생성 접근자 `SharedDesignSystemInterfaceAsset.Colors.<name>.swiftUIColor` ([Color+Extension.swift](../../Projects/Shared/SharedDesignSystem/Interface/Color/Color+Extension.swift) 가 `Asset` 으로 축약해 감싼다). 에셋명이 HEX 라 생성 이름도 `color636777` — 의미를 입히는 게 팔레트 enum 의 일이다. 에셋을 지우거나 이름을 바꾸면 팔레트에서 컴파일 에러가 난다.
- **스펙 검증**: `ColorPaletteTests` 가 토큰 → 에셋 RGB 를 Figma 확정 HEX 와 1:1 대조. static-library 모드의 번들(`Bundle.module`) 파손도 여기서 잡힌다.
- **Figma 주의**: Color Guide 의 positive 계열 HEX **텍스트 라벨**(주황 계열)은 오기 — 실제 스와치·바인딩 변수(청록, 위 표 값)가 확정이다. 라벨만 보고 옮기지 말 것 (디자이너 정정 요청 중).
- **다크모드 미반영**: 각 토큰은 현재 단일 appearance(universal). 도입 결정 시 colorset 에 dark variant 추가.
- **raw 값 보류 승격**: Figma 에서 변수 미바인딩 raw 값(예: 프리로드 하단 초록 사면의 그라데이션 #89E377·#60D549)은 섣불리 토큰화하지 않는다 — 사용처 private 상수 + 주석으로 보류하고, 디자인 시스템에 변수가 생기면 승격.
- **승격 대기 — 팔레트 공백**: `hilit green/200` #D2EFCC(`ReportCard` 접힌 줄 밴드)는 **이름 붙은 Figma 변수인데 대응 토큰이 없다** — 팔레트 그린이 g500·g600·g800 뿐이라 200 자리가 비어 있다. 위 raw 값 보류와 달리 승격 근거(이름 붙은 변수)가 이미 있어 **승격 후보**다(`ColorD2EFCC` + `HilitGreen.g200`). 그때까지 `ReportCard.swift` 파일 내부 private 상수.
