# 색상 토큰

`SharedDesignSystem/Interface/Color/` — 순수 Swift 2-tier. 화면 코드는 **시맨틱 별칭 우선**, 원색이 꼭 필요할 때만 `Color.ds(.gray300)`.

## Tier 1 · 프리미티브 (`DSColorToken`)

Figma «Part4 지인 피드백 · 여기가 최종» 변수 1:1. 접근: `Color.ds(.green800)`. Figma 변수명 대조는 `DSColorToken.figmaName`.

| 그룹 | 토큰 (hex) |
|---|---|
| green | `green500 #ACEBA0` · `green600 #88C97C` · `green800 #106100` |
| gray | `gray50 #F6F7F9` · `gray100 #EBECF1` · `gray200 #BCBEC6` · `gray300 #9DA0AC` · `gray400 #8A8D9C` · `gray500 #6D7183` · `gray600 #636777` · `gray700 #494C58` · `gray800 #31333B` · `gray900 #27282F` |
| neutral | `white #FFFFFF` · `black800 #1A1B1F` |
| positive | `positive200 #DDFAFF` · `positive500 #00CFEF` · `positive800 #008A9F` |
| error | `error200 #FFEBEB` · `error500 #FF5757` |

## Tier 2 · 시맨틱 별칭 (`Color.ds*`)

프리미티브 참조. **잠정 매핑** — 화면 단계에서 실제 컴포넌트에 대보며 확정.

| 별칭 | → 프리미티브 | 용도 |
|---|---|---|
| `dsBrand` | green800 | primary 액션·강조 |
| `dsBrandSoft` | green500 | 옅은 강조·선택 배경 |
| `dsBgLight` | gray50 | 라이트 화면 배경 |
| `dsBgDark` | black800 | 다크 화면 배경(영상·로딩) |
| `dsSurfaceDark` | gray900 | 다크 위 표면 |
| `dsTextPrimary` | gray900 | 기본 텍스트(라이트 위) |
| `dsTextOnDark` | white | 다크 위 텍스트 |
| `dsTextSecondary` | gray500 | 보조 텍스트 |
| `dsTextTertiary` | gray400 | 3차·비활성 |
| `dsSeparator` | gray100 | 구분선 |
| `dsPositive` | positive500 | 긍정 상태 |
| `dsError` | error500 | 오류·부정 |

## 규칙

- 라이트/다크 **적응형 아님** — 최종 디자인이 화면마다 고정 톤을 쓴다. 화면이 어느 배경인지에 따라 `dsBgLight`/`dsBgDark`·`dsTextPrimary`/`dsTextOnDark` 를 명시적으로 고른다.
- 팔레트 확장은 `DSColorToken` 케이스 추가(+`hex`/`figmaName`). 값 단일 소스 = 코드(`DSColorToken`) — 이 문서와 어긋나면 코드 우선. 시맨틱 별칭 매핑(별칭→프리미티브)은 `DSColorTests` 가 고정.
