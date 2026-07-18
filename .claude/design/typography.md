# 타이포그래피 — 상세

`DSTypography` 토큰 레퍼런스. 단일 소스는 [DSTypography.swift](../../Projects/Shared/SharedDesignSystem/Interface/Typography/DSTypography.swift) — 어긋나면 코드가 우선이고 이 문서를 갱신한다. 원본 스펙: Figma «Hilit_Style Guide_1» (node 988-3149).

## 사용법

```swift
Text("제목").dsTypography(.head1)   // 기본 — 폰트+행간+자간 일괄 (Figma 스펙 1:1)
Font.ds(.body2)                     // 폰트만 필요한 특수한 경우 (행간·자간 빠짐 주의)
```

## 스케일 (Pretendard, 23종)

토큰명은 Figma 스타일명의 앞부분 (head1 = `head1_sb_32`). `figmaName` 프로퍼티로 전체명 확인 가능.

| 레벨 | 토큰 (웨이트) | Size | Line Height |
|---|---|---|---|
| Head | head1(sb) · head2(m) | 32 | 38 (120%) |
| Head | head3(sb) · head4(m) · head5(r) | 24 | 31 (130%) |
| Sub | sub1(sb) · sub2(m) · sub3(r) | 22 | 29 (130%) |
| Sub | sub4(sb) · sub5(m) · sub6(r) | 20 | 26 (130%) |
| Sub | sub7(sb) · sub8(m) · sub9(r) | 18 | 23 (130%) |
| Body | body1(sb) · body2(m) · body3(r) | 16 | 21 (130%) |
| Body | body4(sb) · body5(m) · body6(r) | 14 | 18 (130%) |
| Body | body7(sb) · body8(m) · body9(r) | 12 | 16 (130%) |

- 자간(Letter Spacing)은 **전 스타일 -2.5%** — 토큰에 내장, 따로 지정하지 않는다.
- 웨이트: sb = SemiBold(600), m = Medium(500), r = Regular(400).

## 구현 노트

- **행간**: SwiftUI 에 line-height 개념이 없어 `lineSpacing + 상하 패딩` 보정으로 Figma px 를 재현 ([View+DSTypography.swift](../../Projects/Shared/SharedDesignSystem/Interface/Typography/View+DSTypography.swift)).
- **Dynamic Type 미반영** (고정 사이즈) — 접근성 대응 결정 시 `Font+DS.swift` 에서 `relativeTo:` 전환.
- **폰트 파일**: `Interface/Resources/Fonts/Pretendard-{Regular,Medium,SemiBold}.otf` — 첫 토큰 접근 시 자동 CoreText 등록(App 세팅 불필요). 새 웨이트는 otf 추가 + `Pretendard.Weight` case 추가.
- **스펙 검증**: 토큰 ↔ Figma 스타일명 1:1 은 `DSTypographyTests` 가 고정. 스케일 개정 시 테스트의 스펙 표부터 Figma 와 대조해 갱신.
- **알려진 Figma 불일치**: `head3_sb_24` 의 실제 텍스트 스타일은 행간 135%인데 스타일가이드 표는 130%/31px. 표 기준(31px)으로 구현 — 디자이너에게 Figma 스타일 수정 요청 상태 (2026-07-18).
