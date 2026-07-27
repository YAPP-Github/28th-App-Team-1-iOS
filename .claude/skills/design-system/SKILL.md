---
name: design-system
description: HILIT 디자인 시스템 레퍼런스·변경 절차. 색·타이포·spacing·아이콘·컴포넌트 관련 질문이나 UI 일관성 점검, DS 토큰·컴포넌트를 추가·수정·삭제할 때 반드시 이 스킬을 쓴다. "이 버튼 무슨 색이야", "그 토큰 뭐였지", "컴포넌트 추가해줘", "UI 일관성 봐줘", "디자인시스템 고쳐줘" 처럼 «디자인시스템»이라는 말이 없어도 DS 자산을 묻거나 건드리는 요청이면 이 스킬이다. Figma MCP 로 시안을 옮길 때도 매핑 근거로 참조한다.
---

# 디자인 시스템 — 참조·변경 절차

**단일 소스는 코드**(`Projects/Shared/SharedDesignSystem/`). 우선순위: 실제 코드 > 상세 문서 > 이 스킬.
이 스킬은 **내용을 갖지 않는다** — 어디를 볼지, 바꿀 때 무엇을 함께 갱신할지만 정한다. 값·목록을 여기 복제하면 두 곳이 어긋난다.

## 절대 규칙

1. **토큰 우선** — 색·타이포·spacing·아이콘은 리터럴 금지. 없으면 만들지 말고 `@ds(...)` 태그로 남긴다(→ `figma-screen` 스킬 §2).
2. **커스텀 만들기 전에 카탈로그 검토** — `design/component.md` 에 같은 모양이 있으면 그게 중복이다.
3. **아이콘 틴트 금지** — 색은 에셋에 구워져 있다. `foregroundStyle` 로 바꾸려 들면 무효다(과거 사고 → `design/lessons.md`).
4. **버튼 상태를 파라미터로 넘기지 않는다** — pressed·disabled 는 `configuration.isPressed`/`@Environment(\.isEnabled)` 몫.
5. **없는 토큰·에셋을 몰래 만들지 않는다** — DS 변경은 아래 «변경 절차» 를 탄다.

## 어디를 읽을까

| 묻는 것 | 읽을 곳 |
|---|---|
| 색 값·팔레트·HEX 역매핑 · **「이런 색」으로 찾기** | `.claude/design/color.md` (생김새 열) |
| 폰트 크기·weight·Figma 스타일명 대응 | `.claude/design/typography.md` |
| 간격·테두리 두께 | `.claude/design/spacing.md` |
| 아이콘·일러스트 · **「이렇게 생긴 아이콘」으로 찾기** | `.claude/design/image.md` (생김새 역매핑 표) |
| 컴포넌트 API·승격 규칙 | `.claude/design/component.md` |
| 과거에 뭘 틀렸나 | `.claude/design/lessons.md` |
| 규칙 요약·영역 인덱스 | `.claude/design.md` |

**로드 규칙** — 간단한 확인은 해당 상세 문서 하나만. 시안을 화면으로 옮기는 작업이면 `figma-screen` 스킬로 넘긴다(이 스킬은 매핑 근거만 제공).

## 변경 절차 (DS 코드를 건드렸으면 반드시)

코드만 고치고 끝내면 다음 세션이 낡은 문서를 믿는다. **바뀐 종류별로 아래를 같은 작업 안에서 갱신한다.**

| 바꾼 것 | 함께 갱신 |
|---|---|
| 색 추가·변경 | `design/color.md` 팔레트 표 · `ColorPaletteTests` 케이스 |
| 타이포 추가·변경 | `design/typography.md` 표 |
| spacing·outline 토큰 | `design/spacing.md` 표 |
| 아이콘·일러스트 에셋 | `design/image.md` 표 (에셋 → `tuist generate` → 패밀리 enum 감싸기 순서는 `design.md` «에셋 로드 규칙») |
| 컴포넌트 추가·API 변경·삭제 | `design/component.md` 해당 표 행 |
| 실수해서 규칙이 생김 | `design/lessons.md` 항목 추가 |
| **심볼·파일 경로 이름 변경** | 옛 이름으로 `grep -rn --include="*.md"` 해서 **걸리는 문서 전부** (lat.md·docs·다른 스킬 포함) |

마지막 줄이 제일 자주 새는 곳이다. 주제가 «색»인 문서만 찾으면 아키텍처 노트·작업 문서에 남은 옛 심볼을 놓친다(→ `design/lessons.md` 3번). 이름을 바꿨으면 반드시 grep 으로 훑는다.

```bash
grep -rn --include="*.md" '옛이름' . | grep -v worktrees
```

## 협업 — 문서 충돌 줄이기

이 레포는 여럿이 DS 를 동시에 만진다. 실측상 허브(`design.md`)가 잎 문서보다 3배 자주 바뀌었다. 그래서:

1. **허브(`design.md`·`CLAUDE.md`)는 되도록 건드리지 않는다.** 영역 인덱스 표는 «어디로 가면 되는지»만 적혀 있고 토큰 개수·컴포넌트 이름을 열거하지 않는다 — 그래야 뭘 추가해도 허브가 안 바뀐다. 열거를 다시 넣지 말 것.
2. **변경은 잎 문서에서.** 새 컴포넌트는 `design/component.md` 의 **자기 카테고리 표**에만 행을 추가한다(버튼 표 / 그 밖 표). 다른 사람 표를 건드리지 않으면 같은 줄에서 만날 일이 없다.
   표 안에서도 **끝에 붙이지 말고 알파벳순 제자리에 끼워 넣는다** — 둘이 동시에 추가해도 서로 다른 줄이라 자동 병합된다. 끝에 붙이면 같은 자리라 반드시 충돌한다.
3. **`lessons.md` 는 append-only** — 항상 파일 끝에 붙인다. `.gitattributes` 가 `merge=union` 으로 잡아둬서 둘이 동시에 추가해도 양쪽 다 남는다(충돌 없음).
4. **한 커밋에 한 영역.** 색 작업과 컴포넌트 작업을 한 커밋에 섞으면 리베이스 때 통째로 충돌한다.
