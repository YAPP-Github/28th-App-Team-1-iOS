# Design System — UI 작업 참조 문서

UI 코드를 작성·수정하기 전에 읽는 디자인 토큰·표준 컴포넌트 레퍼런스. 단일 소스는 `Shared/SharedDesignSystem` 모듈 코드이며, 이 문서는 그 사용 규칙 요약이다.

> **현재 상태**: SharedDesignSystem 은 이관 대기 (골격만 존재). 아래 토큰은 이관될 표준형 — 코드 이관 후 이 문서와 실제 토큰이 어긋나면 코드가 우선이고 이 문서를 갱신한다.

## 사용 규칙 (필수)

- **토큰 우선, 하드코딩 금지** — `Color.blue`, `16`, `.font(.system(size:))` 같은 리터럴 대신 항상 아래 토큰을 쓴다.
- 의존은 `.shared(interface: .designSystem)` — 모든 레이어에서 가능. Implementation 은 App/Example 만 link.

## 토큰

### 색상 (`Color`)

| 토큰 | 용도 |
|---|---|
| `Color.dsPrimary` | 브랜드 주 색상 (버튼·강조) |
| `Color.dsBackground` | 화면 배경 |
| `Color.dsTextPrimary` | 본문 텍스트 |
| `Color.dsTextSecondary` | 보조 텍스트 |

### 타이포 (`Font`)

`Font.dsLargeTitle` ~ `Font.dsCaption` 8 단계. 시스템 `.font(.title)` 대신 `ds*` 단계를 쓴다.

### Spacing (`CGFloat`)

`CGFloat.dsXS`(4) ~ `CGFloat.dsXXL`(32). padding·spacing 수치는 이 단계에서 고른다 (예: `.padding(.dsL)`).

## 컴포넌트

- `PrimaryButton` — 표준 주 버튼. 커스텀 버튼 스타일을 새로 만들기 전에 이걸 먼저 검토.

## 에셋 로드 (새 색·이미지 추가 시)

1. `Resources/Colors.xcassets` · `Assets.xcassets` 에 에셋 추가
2. `Color.load(_:)` · `Image.load(_:)` **단일 seam** 으로만 로드해 토큰으로 노출 — 번들 해석 일원화 + 개발 빌드 `assert` 로 오타 검출
3. 이미지 토큰은 `Image.DS` 네임스페이스 — 늘어나면 `Ic`/`Img` 중첩 enum 으로 묶는다 (GmoneyTrans 방식)
