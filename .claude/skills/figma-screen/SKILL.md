---
name: figma-screen
description: 피그마 시안을 이 레포의 SwiftUI 화면으로 옮긴다. 피그마 링크(figma.com/design/…)나 노드 id 를 주며 "이 화면 그려줘 / 옮겨줘 / 만들어줘 / 코드로 바꿔줘" 라고 하면 반드시 이 스킬을 쓴다. "피그마"라는 단어가 없어도 시안·디자인·목업을 화면 코드로 옮기려는 요청이면 이 스킬이다. DesignSystem 에 있는 토큰·컴포넌트로 최대한 매핑하고, 아직 없는 것만 raw 수치로 두되 `@ds(...)` 태그 주석을 달아 나중에 토큰이 생기면 기계적으로 일괄 치환할 수 있게 남긴다.
---

# 피그마 시안 → SwiftUI 화면

시안을 화면 코드로 옮기되, **DesignSystem 이 아직 못 덮는 부분을 눈에 보이게 남긴다.**

왜 이렇게 하나: 지금 토큰이 없다고 raw 수치를 그냥 박아두면, 나중에 토큰이 생겨도 어디를 고쳐야 하는지 찾을 방법이 없다. 반대로 없는 토큰을 억지로 만들면 시안 확정 전에 DesignSystem 이 오염된다. 그래서 **raw 로 두되 기계가 찾을 수 있는 표식을 남기는 것** — 나중에 `grep '@ds('` 한 번이 치환 대상 전체 목록이 된다.

## 0. 준비

1. **`.claude/design.md` 를 먼저 읽는다.** 토큰·공용 컴포넌트·에셋 로드 규칙의 영역 인덱스가 거기 있다. 필요하면 `.claude/design/{color,typography,spacing,component,image}.md` 로 들어간다. 이걸 건너뛰면 이미 있는 토큰을 raw 로 박게 된다 — 이 스킬이 막으려는 바로 그 일이다.
2. **시안을 읽는다.** Figma MCP(`get_design_context`·`get_screenshot`·`get_variable_defs`)를 쓴다. 플러그인 스킬 `figma:figma-design-to-code`·`figma:figma-swiftui` 가 추출 절차를 담당하니 그쪽을 따르되, **매핑·주석 규칙은 이 스킬이 우선한다** (그 스킬들은 raw 수치를 그대로 쓰라고 할 수 있다).
3. **MCP 가 인증 안 돼 있으면** 거기서 멈추지 말고 사용자에게 스크린샷이나 값 목록(색·크기·폰트·간격)을 달라고 한 뒤 같은 규칙으로 진행한다.

## 1. 토큰 매핑 — 있는 것부터 쓴다

Figma 의 raw 수치를 그대로 박지 않는다. 각 값마다 대응 토큰을 먼저 찾는다.

| 시안이 주는 것 | 먼저 찾을 곳 | 형태 |
|---|---|---|
| 색 HEX | `design/color.md` 팔레트 23색 | `Color.GrayScale.g800` · `Color.Error.e500` |
| 폰트(`head1_sb_32` 등) | `design/typography.md` 25종 | `.dsTypography(.head3)` |
| padding·gap | `design/spacing.md` (4~24) | `.padding(.ds(.p20))` |
| 버튼·칩·태그·토스트 | `design/component.md` | `ButtonLarge("계속하기", .bottom) { … }` · `.buttonStyle(.medium(.green))` |
| 아이콘·일러스트 | `design/image.md` | `Image.Cancel.white24` · `Image.Img.…` (틴트 금지 — 색변형별 에셋) |

**근사 판단**: 시안 값이 토큰과 미세하게 다르면(#FF5858 vs #FF5757) 토큰을 쓴다 — 팔레트가 진실이다. 다만 눈에 띄게 다르면 토큰을 쓰되 원본을 태그로 남긴다(§2 화살표 형태). "눈에 띄는가"의 기준은 나란히 놓고 구별되는가다.

**커스텀 만들기 전에 `design/component.md` 카탈로그를 먼저 검토한다.** 손으로 만든 버튼이 기존 스타일과 같은 모양이면 그건 중복이다.

## 2. `@ds` 태그 — 없는 것을 남긴다

토큰·컴포넌트가 없어 raw 로 둔 자리마다 **바로 윗줄에** 한 줄 태그를 단다.

```
// @ds(<종류>): <raw 값> — <역할>
// @ds(<종류>): <raw 값> → <쓴 토큰> — <역할>      ← 토큰으로 근사했고 원본을 보존할 때
```

- **종류** — `color` · `typography` · `spacing` · `radius` · `icon` · `component` · `layout` 중 하나. 나중 치환 스크립트가 이걸로 분류한다.
- **raw 값** — 시안이 준 값 그대로. 이게 없으면 치환할 때 원본을 다시 피그마에서 찾아야 한다.
- **역할** — 의미. 나중에 어느 토큰으로 갈지는 값이 아니라 **역할**이 결정한다. "빨강"이 아니라 "에러 텍스트", "12"가 아니라 "카드 모서리".

```swift
// @ds(radius): 12 — 카드 모서리 (DSRadius 토큰 없음)
.clipShape(RoundedRectangle(cornerRadius: 12))

// @ds(spacing): 32 — 섹션 사이 (spacing 토큰은 4~24 뿐)
.padding(.top, 32)

// @ds(color): #FF5858 → Error.e500 — 에러 텍스트, 시안보다 약간 진함
.foregroundStyle(Color.Error.e500)
```

컴포넌트 하나가 통째로 없으면 만든 뷰·프로퍼티 위에 단다.

```swift
// @ds(component): 바텀시트 — detent medium/large + 드래그 인디케이터. 공용 컴포넌트 없음
private var detailSheet: some View { … }
```

지킬 것 두 개:

- **태그 없이 raw 를 남기지 않는다.** 태그 없는 raw 는 나중에 영영 안 찾아진다. 반대로 토큰을 쓴 자리엔 태그를 달지 않는다 — 이미 해결된 자리라 치환 목록을 오염시킨다.
- **없는 토큰·에셋을 몰래 만들지 않는다.** 색 에셋 추가·`DSRadius` 신설 같은 건 DesignSystem 변경이라 별도 판단이 필요하다. 이 스킬은 표식만 남기고 제안은 결과 보고에 적는다. 임시 방편(없는 아이콘을 비슷한 걸 회전시켜 버티는 등)도 태그 대상이다.

파일 맨 위에는 출처를 남긴다. 나중에 시안과 대조할 때 필요하다.

```swift
// Figma: «리포트 / 1차 리포트» https://figma.com/design/…?node-id=1609-9019
```

## 3. 파일 배치·형태

레포 관행 그대로 만든다 (`.claude/CLAUDE.md` «TCA 패턴»).

- 위치: `Projects/Feature/Feature{X}/Sources/Screens/{화면}/{화면}View.swift`. 대상 Feature 가 안 정해졌으면 화면 이름·도메인으로 추정해 고르고 결과 보고에 어디에 넣었는지 밝힌다.
- 형태: `@ViewAction(for:)` + `@Bindable var store` + `public struct …View: View`. 모듈 경계를 넘으니 `public init(store:)` 필수.
- **리듀서를 새로 만들지 않는다.** 짝이 되는 `{화면}Feature.swift` 가 없으면 View 만 만들고, 필요한 액션(`userTapped…`)을 결과 보고에 목록으로 남긴다. 있으면 기존 Action 케이스만 쓴다.
- body 는 큰 덩어리를 `private var` 로 쪼갠다 — 시안의 섹션 경계를 그대로 따르면 나중에 대조하기 쉽다.
- 하단에 `#Preview("…")` 를 최소 1개 둔다. 상태별로 여러 개가 필요하면 `tca-preview` 스킬로 넘긴다.

## 4. 검증

```bash
xcrun swiftc -parse <만든 파일>
swiftlint lint --quiet --config .swiftlint.yml <만든 파일>
```

둘 다 통과시킨다. 전체 빌드·프리뷰 확인은 사용자 몫이니 스킬이 `xcodebuild` 를 돌리지 않는다 — 대신 어떤 스킴으로 열면 되는지 알려준다.

## 결과 보고 형식

1. **만든 파일** 경로와 화면 구조 한 줄 요약.
2. **매핑한 것** — 토큰으로 흡수한 항목을 종류별로 한 줄씩 (예: "색 6곳 → GrayScale/Error 팔레트, 타이포 4곳 → head3·body3").
3. **남긴 `@ds` 태그 목록** — 종류 · 값 · 역할 · 파일:줄. **이게 이 스킬의 핵심 산출물이다.** 나중 치환 작업의 입력이자, DesignSystem 에 무엇이 부족한지 보여주는 재고 목록이다.
4. **DesignSystem 제안** — 태그가 여러 곳에서 같은 걸 가리키면(예: radius 12 가 5곳) 토큰 신설 후보로 적는다. 만들지는 않는다.
5. **필요한 Action** — 리듀서가 없거나 케이스가 모자라 연결 못 한 인터랙션.
6. 확인 방법: `Feature{X}` 스킴 → 해당 View 파일 → 캔버스.
