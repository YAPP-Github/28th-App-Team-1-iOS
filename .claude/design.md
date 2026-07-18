# Design System — UI 작업 인덱스

UI 코드를 작성·수정하기 전에 읽는 진입점. 여기엔 **규칙과 영역별 요약만** 두고, 상세는 각 영역 문서 포인터를 따라간다 (CLAUDE.md → design.md 패턴의 재귀 적용). 단일 소스는 `Shared/SharedDesignSystem` 모듈 코드 — 문서와 어긋나면 코드가 우선.

## 사용 규칙 (필수)

- **토큰 우선, 하드코딩 금지** — `Color.blue`, `16`, `.font(.system(size:))` 같은 리터럴 대신 항상 토큰을 쓴다.
- 의존은 `.shared(interface: .designSystem)` — 모든 레이어에서 가능. Implementation 은 App/Example 만 link.

## 영역별 인덱스

| 영역 | 상태 | 요약 | 상세 |
|---|---|---|---|
| 타이포그래피 | ✅ 구현 | `.dsTypography(.head1)` — Pretendard 23종 (head1~5·sub1~9·body1~9), 행간·자간 내장 | **`.claude/design/typography.md`** |
| 색상 | 이관 대기 | `Color.dsPrimary` / `dsBackground` / `dsTextPrimary` / `dsTextSecondary` 시맨틱 토큰 예정 | 구현 시 분리 |
| Spacing | 이관 대기 | `CGFloat.dsXS`(4) ~ `dsXXL`(32), `.padding(.dsL)` 식 사용 예정 | 구현 시 분리 |
| 컴포넌트 | 이관 대기 | `PrimaryButton` 등 — 커스텀 만들기 전에 표준 컴포넌트 먼저 검토 | 구현 시 분리 |

상세 문서 분리 기준: **구현이 실체를 갖는 시점**에 `.claude/design/<영역>.md` 로 뺀다. 몇 줄짜리 예정 항목까지 미리 쪼개지 않는다 (파일 하나당 Read 비용).

## 에셋 로드 규칙 (새 색·이미지 추가 시)

1. `Resources/Colors.xcassets` · `Assets.xcassets` 에 에셋 추가
2. `Color.load(_:)` · `Image.load(_:)` **단일 seam** 으로만 로드해 토큰으로 노출 — 번들 해석 일원화 + 개발 빌드 `assert` 로 오타 검출
3. 이미지 토큰은 `Image.DS` 네임스페이스 — 늘어나면 `Ic`/`Img` 중첩 enum 으로 묶는다 (GmoneyTrans 방식)
